import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import '../../data/datasources/local/local_storage.dart';

class ApiClient {
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
          if (!options.headers.containsKey('Authorization')) {
            final token = await storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final isUnauthorized = statusCode == 401;
          final isRefreshRequest =
              error.requestOptions.path.endsWith(ApiConstants.refreshToken);
          final alreadyRetried =
              error.requestOptions.extra['retried'] == true;

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
}
