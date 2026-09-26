import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../services/storage_service.dart';

class ApiProvider {
  ApiProvider({Dio? client, StorageService? storageService})
    : dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
              headers: const {Headers.acceptHeader: Headers.jsonContentType},
            ),
          ) {
    if (storageService != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final path = Uri.parse(options.path).path;
            final isPublic =
                const {
                  AppConfig.loginEndpoint,
                  AppConfig.signup,
                  AppConfig.refreshToken,
                }.any(
                  (publicPath) =>
                      path == publicPath || path.endsWith(publicPath),
                );
            if (isPublic) {
              handler.next(options);
              return;
            }

            try {
              final token = await storageService.getAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            } catch (error) {
              handler.reject(
                DioException(requestOptions: options, error: error),
              );
            }
          },
        ),
      );
    }
  }

  final Dio dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return dio.post<dynamic>(path, data: data);
  }
}
