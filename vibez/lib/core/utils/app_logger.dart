import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static final AppLogger instance = AppLogger._();

  AppLogger._();

  void debug(String message, {Object? data}) {
    _log(level: LogLevel.debug, message: message, data: data);
  }

  void info(String message, {Object? data}) {
    _log(level: LogLevel.info, message: message, data: data);
  }

  void warning(String message, {Object? data}) {
    _log(level: LogLevel.warning, message: message, data: data);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    final logMsg = '[ERROR] $message${error != null ? ' | $error' : ''}';
    debugPrint(logMsg);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    developer.log(
      message,
      name: 'APP',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log({required LogLevel level, required String message, Object? data}) {
    final logMsg = data == null
        ? '[${level.name.toUpperCase()}] $message'
        : '[${level.name.toUpperCase()}] $message | $data';
    debugPrint(logMsg);
    developer.log(
      logMsg,
      name: 'APP',
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }
}

