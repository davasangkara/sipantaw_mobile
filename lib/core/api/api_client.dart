import 'package:dio/dio.dart';
import 'api_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,  // ← langsung, tanpa Duration()
      receiveTimeout: ApiConfig.receiveTimeout,  // ← langsung, tanpa Duration()
      headers: {
        'Accept'       : 'application/json',
        'Content-Type' : 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await TokenStorage.clearAll();
        }
        return handler.next(error);
      },
    ));

    return dio;
  }

  static Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      instance.get(path, queryParameters: params);

  static Future<Response> post(String path, {dynamic data}) =>
      instance.post(path, data: data);

  static Future<Response> put(String path, {dynamic data}) =>
      instance.put(path, data: data);

  static Future<Response> patch(String path, {dynamic data}) =>
      instance.patch(path, data: data);

  static Future<Response> delete(String path) =>
      instance.delete(path);
}