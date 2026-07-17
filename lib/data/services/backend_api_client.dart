import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'token_storage_service.dart';

class BackendApiClient {
  BackendApiClient({
    required TokenStorageService tokenStorage,
    String baseUrl = 'http://localhost:3000',
  })  : _tokenStorage = tokenStorage,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('Backend API error: ${error.requestOptions.path} ${error.message}');
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorageService _tokenStorage;

  Future<void> saveToken(String token) => _tokenStorage.writeToken(token);
  Future<void> clearToken() => _tokenStorage.deleteToken();
  Future<String?> getToken() => _tokenStorage.readToken();

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) async {
    return _dio.post<T>(path, data: data);
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

String handleDioError(DioException error) {
  final response = error.response;
  if (response != null && response.data is Map<String, dynamic>) {
    final data = response.data as Map<String, dynamic>;
    final message = data['error'] as String?;
    if (message != null && message.isNotEmpty) return message;
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.connectionError) {
    return 'Could not reach the Coleggo server. Please check your connection.';
  }
  return 'Something went wrong. Please try again.';
}
