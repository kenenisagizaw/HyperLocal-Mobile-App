import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/datasources/local/local_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static const bool _enableAuthDebug = true;

  static Future<Dio> create() async {
    final directory = await getApplicationDocumentsDirectory();
    final storage = LocalStorage();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${directory.path}/.cookies/'),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final existing = options.headers['Authorization'];
          final hasAuth = existing is String && existing.isNotEmpty;
          if (!hasAuth) {
            final token = await storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (_enableAuthDebug &&
              response.requestOptions.path.contains(ApiConstants.authBase)) {
            final setCookie = response.headers.map['set-cookie'];
            debugPrint('[auth] set-cookie: ${setCookie ?? const []}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final isUnauthorized = statusCode == 401;
          final isRefreshRequest = error.requestOptions.path.endsWith(
            ApiConstants.refreshToken,
          );
          final alreadyRetried = error.requestOptions.extra['retried'] == true;
          final isRevoked = _isTokenRevoked(error.response?.data);

          if (isUnauthorized && !isRefreshRequest && !alreadyRetried) {
            error.requestOptions.extra['retried'] = true;
            final refreshed = await _refreshAccessToken(
              cookieJar: cookieJar,
              storage: storage,
              baseUrl: ApiConstants.baseUrl,
            );
            if (refreshed) {
              final newToken = await storage.getAccessToken();
              if (newToken != null && newToken.isNotEmpty) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
              }
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }

          if (isUnauthorized &&
              (isRefreshRequest || alreadyRetried || isRevoked)) {
            await storage.clearAccessToken();
            await cookieJar.deleteAll();
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Future<bool> _refreshAccessToken({
    required CookieJar cookieJar,
    required LocalStorage storage,
    required String baseUrl,
  }) async {
    try {
      final refreshUri = Uri.parse(baseUrl);
      if (_enableAuthDebug) {
        final cookies = await cookieJar.loadForRequest(refreshUri);
        final cookieNames = cookies.map((cookie) => cookie.name).toList();
        debugPrint(
          '[auth] refresh-token cookies: count=${cookies.length} names=$cookieNames',
        );
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      );
      refreshDio.interceptors.add(CookieManager(cookieJar));
      final response = await refreshDio.post(ApiConstants.refreshToken);
      if (_enableAuthDebug) {
        debugPrint('[auth] refresh-token status=${response.statusCode}');
      }
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final inner = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        final token = inner['token'] ?? inner['accessToken'];
        if (token is String && token.isNotEmpty) {
          await storage.saveAccessToken(token);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static bool _isTokenRevoked(dynamic data) {
    final message = _extractMessage(data);
    if (message == null) {
      return false;
    }
    final normalized = message.trim().toLowerCase();
    return normalized == 'token revoked' ||
        normalized == 'refresh token revoked' ||
        normalized == 'access token revoked';
    return false;
  }

  static String? _extractMessage(dynamic data) {
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
}
