import 'package:dio/dio.dart';
import 'package:vibez/core/utils/app_logger.dart';

class ErrorInterceptor extends Interceptor {
  final AppLogger _logger = AppLogger.instance;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;

    _logger.error(
      '${request.method} ${request.path} '
      '[${err.response?.statusCode ?? 'UNKNOWN'}]',
      error: err,
      stackTrace: err.stackTrace,
    );

    handler.next(err);
  }
}
