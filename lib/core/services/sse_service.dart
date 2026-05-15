import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/datasources/local/local_storage.dart';
import '../constants/api_constants.dart';

/// Connection status for an SSE stream.
enum SseConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// A single parsed SSE event.
class SseEvent {
  SseEvent({required this.event, required this.data, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  final String event;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

/// Generic SSE client that connects to a single SSE endpoint.
///
/// Parses the standard SSE format:
/// ```
/// event: <name>
/// data: <json>
/// ```
///
/// Automatically reconnects with exponential backoff.
class SseService {
  SseService({required this.streamPath});

  /// The URL path for this SSE stream (e.g. `/api/notifications/stream`).
  final String streamPath;

  final LocalStorage _storage = LocalStorage();
  final StreamController<SseEvent> _eventController =
      StreamController<SseEvent>.broadcast();
  final StreamController<SseConnectionStatus> _statusController =
      StreamController<SseConnectionStatus>.broadcast();

  HttpClient? _httpClient;
  StreamSubscription<String>? _lineSubscription;
  bool _intentionalDisconnect = false;
  SseConnectionStatus _currentStatus = SseConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  static const int _maxReconnectDelaySecs = 30;
  static const int _initialReconnectDelaySecs = 1;

  /// Stream of parsed SSE events.
  Stream<SseEvent> get events => _eventController.stream;

  /// Stream of connection status changes.
  Stream<SseConnectionStatus> get connectionStatus => _statusController.stream;

  /// Current connection status.
  SseConnectionStatus get currentStatus => _currentStatus;

  /// Whether the stream is currently connected.
  bool get isConnected => _currentStatus == SseConnectionStatus.connected;

  /// Whether the stream is currently connecting or reconnecting.
  bool get isConnecting =>
      _currentStatus == SseConnectionStatus.connecting ||
      _currentStatus == SseConnectionStatus.reconnecting;

  /// Connect to the SSE endpoint.
  Future<void> connect() async {
    if (isConnected || isConnecting) return;
    await _connect();
  }

  Future<void> _connect() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      _updateStatus(SseConnectionStatus.disconnected);
      debugPrint('SSE ($streamPath): skipped — no token');
      return;
    }

    _intentionalDisconnect = false;
    _updateStatus(
      _reconnectAttempts == 0
          ? SseConnectionStatus.connecting
          : SseConnectionStatus.reconnecting,
    );

    try {
      _httpClient?.close(force: true);
      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 15);

      final url = Uri.parse(
        '${ApiConstants.baseUrl}$streamPath?token=$token',
      );

      debugPrint('SSE ($streamPath): connecting to $url');

      final request = await _httpClient!.getUrl(url);
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint(
          'SSE ($streamPath): HTTP ${response.statusCode}',
        );
        _updateStatus(SseConnectionStatus.error);
        _scheduleReconnect();
        return;
      }

      _reconnectAttempts = 0;
      _updateStatus(SseConnectionStatus.connected);
      debugPrint('SSE ($streamPath): connected');

      // Parse the SSE stream line by line.
      String currentEvent = '';
      StringBuffer dataBuffer = StringBuffer();

      _lineSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            dataBuffer.write(line.substring(5).trim());
          } else if (line.isEmpty) {
            // Empty line = end of event block.
            if (currentEvent.isNotEmpty || dataBuffer.isNotEmpty) {
              _processEvent(currentEvent, dataBuffer.toString());
            }
            currentEvent = '';
            dataBuffer = StringBuffer();
          }
        },
        onDone: () {
          debugPrint('SSE ($streamPath): stream ended');
          if (!_intentionalDisconnect) {
            _updateStatus(SseConnectionStatus.reconnecting);
            _scheduleReconnect();
          } else {
            _updateStatus(SseConnectionStatus.disconnected);
          }
        },
        onError: (error) {
          debugPrint('SSE ($streamPath): stream error: $error');
          _updateStatus(SseConnectionStatus.error);
          if (!_intentionalDisconnect) {
            _scheduleReconnect();
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('SSE ($streamPath): connect error: $e');
      _updateStatus(SseConnectionStatus.error);
      if (!_intentionalDisconnect) {
        _scheduleReconnect();
      }
    }
  }

  void _processEvent(String eventName, String rawData) {
    // Ignore keep-alive pings.
    if (eventName == 'ping' || eventName == 'heartbeat') {
      debugPrint('SSE ($streamPath): keep-alive received');
      return;
    }

    // If no explicit event name, use 'message' (SSE default).
    final name = eventName.isEmpty ? 'message' : eventName;

    Map<String, dynamic> data;
    if (rawData.isEmpty) {
      data = <String, dynamic>{};
    } else {
      try {
        final decoded = json.decode(rawData);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = decoded.cast<String, dynamic>();
        } else {
          data = {'value': decoded};
        }
      } catch (_) {
        data = {'raw': rawData};
      }
    }

    debugPrint('SSE ($streamPath): event "$name"');
    _eventController.add(SseEvent(event: name, data: data));
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delaySecs = (_initialReconnectDelaySecs * (1 << _reconnectAttempts))
        .clamp(1, _maxReconnectDelaySecs);

    debugPrint('SSE ($streamPath): reconnecting in ${delaySecs}s '
        '(attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
      if (!_intentionalDisconnect) {
        _connect();
      }
    });
  }

  /// Reconnect if not already connected and not intentionally disconnected.
  Future<void> reconnectIfNeeded() async {
    if (_intentionalDisconnect || isConnected || isConnecting) return;
    await connect();
  }

  /// Disconnect the SSE stream.
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _lineSubscription?.cancel();
    _lineSubscription = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _reconnectAttempts = 0;
    _updateStatus(SseConnectionStatus.disconnected);
    debugPrint('SSE ($streamPath): disconnected');
  }

  void _updateStatus(SseConnectionStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Release all resources.
  void dispose() {
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}
