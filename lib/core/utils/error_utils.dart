import 'package:dio/dio.dart';

class ErrorUtils {
  static const String _networkMessage =
      'Network error. Check your connection and try again.';
  static const String _serverMessage =
      'Server error. Please try again shortly.';
  static const String _genericMessage =
      'Something went wrong. Please try again.';

  static String? friendlyMessage(
    DioException error, {
    Map<int, String>? statusMessages,
    String? fallbackMessage,
  }) {
    if (_isNetworkError(error)) {
      return _networkMessage;
    }

    final statusCode = error.response?.statusCode ?? 0;
    if (statusMessages != null && statusMessages.containsKey(statusCode)) {
      return statusMessages[statusCode];
    }

    if (statusCode >= 500) {
      return _serverMessage;
    }

    final rawMessage = _extractMessage(error) ?? fallbackMessage;
    if (rawMessage == null || rawMessage.trim().isEmpty) {
      return fallbackMessage ?? _genericMessage;
    }

    final normalized = rawMessage.trim().toLowerCase();
    if (_isServerNoise(normalized)) {
      return _serverMessage;
    }

    return rawMessage;
  }

  static bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  static String? _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return null;
  }

  static bool _isServerNoise(String message) {
    return message.contains('error 5000') ||
        message.contains('lbraty') ||
        message.contains('library') ||
        message.contains('internal');
  }
}
