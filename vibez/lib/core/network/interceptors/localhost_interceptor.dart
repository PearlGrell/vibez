import 'dart:io';

import 'package:dio/dio.dart';

class LocalhostInterceptor extends Interceptor{
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if(Platform.isAndroid && options.baseUrl.contains("localhost")) {
      options.baseUrl = options.baseUrl.replaceAll(
        "localhost", "10.0.2.2");
    }
    handler.next(options);
  }
}