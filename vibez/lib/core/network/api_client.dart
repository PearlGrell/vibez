import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vibez/core/network/interceptors/auth_interceptor.dart';
import 'package:vibez/core/network/interceptors/error_interceptor.dart';
import 'package:vibez/core/network/interceptors/localhost_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  static final ApiClient instance = ApiClient._();

  ApiClient._();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    final cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage(path.join(dir.path, '.cookies')),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl:
            '${dotenv.get('API_URL', fallback: 'http://localhost:3000')}/api',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.interceptors.add(LocalhostInterceptor());
    _dio.interceptors.add(AuthInterceptor(_dio, cookieJar));
    _dio.interceptors.add(ErrorInterceptor());
  }

  Future<T> get<T>({
    required String endpoint,
    Map<String, dynamic>? queries,
    bool secure = false,
  }) async {
    final response = await _dio.get<T>(
      endpoint,
      queryParameters: queries,
      options: Options(extra: {'secure': secure}),
    );

    return response.data as T;
  }

  Future<T> post<T>({
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queries,
    bool secure = false,
  }) async {
    final response = await _dio.post<T>(
      endpoint,
      data: body,
      queryParameters: queries,
      options: Options(extra: {'secure': secure}),
    );

    return response.data as T;
  }

  Future<T> put<T>({
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queries,
    bool secure = false,
  }) async {
    final response = await _dio.put<T>(
      endpoint,
      data: body,
      queryParameters: queries,
      options: Options(extra: {'secure': secure}),
    );

    return response.data as T;
  }

  Future<T> patch<T>({
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queries,
    bool secure = false,
  }) async {
    final response = await _dio.patch<T>(
      endpoint,
      data: body,
      queryParameters: queries,
      options: Options(extra: {'secure': secure}),
    );

    return response.data as T;
  }

  Future<T> delete<T>({
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queries,
    bool secure = false,
  }) async {
    final response = await _dio.delete<T>(
      endpoint,
      data: body,
      queryParameters: queries,
      options: Options(extra: {'secure': secure}),
    );

    return response.data as T;
  }
}
