import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/sse_service.dart';

/// Represents a live location point received via SSE.
class LocationPoint {
  LocationPoint({
    required this.bookingId,
    required this.userId,
    required this.position,
    required this.timestamp,
  });

  final String bookingId;
  final String userId;
  final LatLng position;
  final DateTime timestamp;
}

/// Manages real-time location sharing state received from the
/// `GET /api/bookings/location-share/stream?token=JWT` SSE endpoint.
///
/// Events:
///   - `location.share.started`  → a user started sharing location
///   - `location.share.stopped`  → a user stopped sharing location
///   - `location.point.received` → a new GPS coordinate arrived
class LocationShareProvider extends ChangeNotifier {
  LocationShareProvider();

  SseService? _sseService;
  StreamSubscription<SseEvent>? _sseSub;

  /// Booking IDs that have active location sharing.
  final Set<String> _activeShares = {};

  /// Latest location point per booking.
  final Map<String, LocationPoint> _latestPoints = {};

  /// Stream of incoming location points for UI to react to.
  final StreamController<LocationPoint> _pointController =
      StreamController<LocationPoint>.broadcast();

  Set<String> get activeShares => Set.unmodifiable(_activeShares);
  Stream<LocationPoint> get locationPoints => _pointController.stream;

  /// Whether a specific booking has active location sharing.
  bool isSharing(String bookingId) => _activeShares.contains(bookingId);

  /// Get the latest known position for a booking.
  LocationPoint? getLatestPoint(String bookingId) => _latestPoints[bookingId];

  /// Initialize with the location-share SSE service.
  void attachSse(SseService sseService) {
    if (_sseService == sseService) return;
    _sseSub?.cancel();
    _sseService = sseService;

    _sseSub = sseService.events.listen(_handleEvent);
  }

  void _handleEvent(SseEvent event) {
    switch (event.event) {
      case 'location.share.started':
        _handleStarted(event.data);
        break;
      case 'location.share.stopped':
        _handleStopped(event.data);
        break;
      case 'location.point.received':
        _handlePoint(event.data);
        break;
      default:
        debugPrint('LocationShareProvider: unknown event ${event.event}');
    }
  }

  void _handleStarted(Map<String, dynamic> data) {
    final bookingId = (data['bookingId'] ?? '').toString();
    if (bookingId.isEmpty) return;

    _activeShares.add(bookingId);
    debugPrint('LocationShareProvider: sharing started for $bookingId');
    notifyListeners();
  }

  void _handleStopped(Map<String, dynamic> data) {
    final bookingId = (data['bookingId'] ?? '').toString();
    if (bookingId.isEmpty) return;

    _activeShares.remove(bookingId);
    _latestPoints.remove(bookingId);
    debugPrint('LocationShareProvider: sharing stopped for $bookingId');
    notifyListeners();
  }

  void _handlePoint(Map<String, dynamic> data) {
    final bookingId = (data['bookingId'] ?? '').toString();
    final userId = (data['userId'] ?? data['senderId'] ?? '').toString();
    final lat = _parseDouble(data['latitude'] ?? data['lat']);
    final lng = _parseDouble(data['longitude'] ?? data['lng'] ?? data['lon']);

    if (bookingId.isEmpty || lat == null || lng == null) {
      debugPrint('LocationShareProvider: invalid point data: $data');
      return;
    }

    final point = LocationPoint(
      bookingId: bookingId,
      userId: userId,
      position: LatLng(lat, lng),
      timestamp: DateTime.tryParse(
            (data['timestamp'] ?? data['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );

    _activeShares.add(bookingId);
    _latestPoints[bookingId] = point;
    _pointController.add(point);
    notifyListeners();
  }

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _pointController.close();
    super.dispose();
  }
}
