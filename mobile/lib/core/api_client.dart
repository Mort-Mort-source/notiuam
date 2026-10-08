import 'package:dio/dio.dart';
import 'constants.dart';
import 'token_storage.dart';

class ApiClient {
  final Dio _dio;
  final TokenStorage _storage;

  ApiClient(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeout,
          receiveTimeout: ApiConfig.timeout,
          contentType: 'application/json',
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccess();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  static String extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.response?.statusCode == 403) return 'Sesión expirada o sin permisos';
      if (error.response?.statusCode == 404) return 'Recurso no encontrado';
      return error.message ?? 'Error de red';
    }
    return error.toString();
  }
}
