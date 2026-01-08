import 'package:dio/dio.dart';

import '../utils/api_config.dart';
import 'session_service.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = SessionManager.instance.accessToken;
          if (token != null && options.headers['Authorization'] == null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final bool isAuthRoute = error.requestOptions.path.startsWith('/auth/');
          final bool alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (status == 401 && !alreadyRetried && !isAuthRoute) {
            final refreshed = await SessionManager.instance.refreshTokens(dio: _dio);
            if (refreshed) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${SessionManager.instance.accessToken}';
              opts.extra['retried'] = true;
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // fallthrough to default handler
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  Dio get dio => _dio;
}
