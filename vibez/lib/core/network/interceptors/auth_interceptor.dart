import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:vibez/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage = TokenStorage.instance;

  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._dio, CookieJar cookieJar)
    : _refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          sendTimeout: _dio.options.sendTimeout,
        ),
      ) {
    _refreshDio.interceptors.add(CookieManager(cookieJar));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.accessToken;

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['_retried'] == true) {
      await _logout();
      return handler.next(err);
    }

    try {
      String? newAccessToken;

      if (_refreshCompleter != null) {
        newAccessToken = await _refreshCompleter!.future;
      } else {
        _refreshCompleter = Completer<String?>();

        try {
          newAccessToken = await _refreshToken();
          _refreshCompleter!.complete(newAccessToken);
        } catch (e) {
          _refreshCompleter!.completeError(e);
          rethrow;
        } finally {
          _refreshCompleter = null;
        }
      }

      if (newAccessToken == null) {
        await _logout();
        return handler.next(err);
      }

      final response = await _retry(err.requestOptions, newAccessToken);

      return handler.resolve(response);
    } catch (_) {
      await _logout();
      return handler.next(err);
    }
  }

  Future<String?> _refreshToken() async {
    final response = await _refreshDio.post('/auth/refresh');

    final accessToken = response.data['accessToken'] as String?;

    if (accessToken == null) {
      return null;
    }

    await _tokenStorage.setAccessToken(accessToken);

    return accessToken;
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';
    requestOptions.extra['_retried'] = true;

    return _dio.fetch(requestOptions);
  }

  Future<void> _logout() async {
    await _tokenStorage.clear();
  }
}
