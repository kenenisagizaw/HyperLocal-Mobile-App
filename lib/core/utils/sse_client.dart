import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SseEvent {
  SseEvent({required this.data, this.event});

  final String data;
  final String? event;
}

class SseConnection {
  SseConnection._(this._client, this._subscription, this._controller);

  final HttpClient _client;
  final StreamSubscription<String> _subscription;
  final StreamController<SseEvent> _controller;

  Stream<SseEvent> get stream => _controller.stream;

  void close() {
    _subscription.cancel();
    _client.close(force: true);
    _controller.close();
  }

  static Future<SseConnection> connect({
    required Uri uri,
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    headers.forEach((key, value) {
      request.headers.set(key, value);
    });
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');

    final response = await request.close();

    final controller = StreamController<SseEvent>.broadcast();
    String? eventName;
    final dataBuffer = StringBuffer();

    void dispatch() {
      if (dataBuffer.isEmpty) {
        eventName = null;
        return;
      }
      controller.add(
        SseEvent(
          data: dataBuffer.toString(),
          event: eventName?.trim().isEmpty == true ? null : eventName,
        ),
      );
      dataBuffer.clear();
      eventName = null;
    }

    final subscription = response
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.isEmpty) {
              dispatch();
              return;
            }
            if (line.startsWith('event:')) {
              eventName = line.substring(6).trim();
              return;
            }
            if (line.startsWith('data:')) {
              final chunk = line.substring(5).trimLeft();
              if (dataBuffer.isNotEmpty) {
                dataBuffer.write('\n');
              }
              dataBuffer.write(chunk);
            }
          },
          onError: controller.addError,
          onDone: () {
            dispatch();
            controller.close();
            client.close();
          },
          cancelOnError: true,
        );

    return SseConnection._(client, subscription, controller);
  }
}
