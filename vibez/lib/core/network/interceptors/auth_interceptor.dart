import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:vibez/core/network/socket_client.dart';
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
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final isRefresh = e.requestOptions.path.contains('/auth/refresh');
        
        if (statusCode == 401 || (isRefresh && (statusCode == 403 || statusCode == 400))) {
          await _logout();
        }
      }
      return handler.next(err);
    }
  }

  Future<String?> _refreshToken() async {
    final response = await _refreshDio.post('/auth/refresh');

    // The API returns the access token under `token` (same shape as
    // /auth/login and /auth/register), NOT `accessToken`. Reading the wrong
    // key made every refresh look like a failure and forced a logout.
    final accessToken = response.data['token'] as String?;

    if (accessToken == null) {
      return null;
    }

    await _tokenStorage.setAccessToken(accessToken);
    SocketClient.instance.reconnect();

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
    SocketClient.instance.disconnect();
  }
}
