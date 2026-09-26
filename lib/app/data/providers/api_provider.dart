import 'package:dio/dio.dart';

import '../../config/app_config.dart';

class ApiProvider {
  ApiProvider({Dio? client})
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
          );

  final Dio dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return dio.post<dynamic>(path, data: data);
  }
}
