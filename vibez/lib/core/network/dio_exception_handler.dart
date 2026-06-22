import 'package:dio/dio.dart';

class DioExceptionHandler {
  static String getMessage(DioException err) {
    final responseData = err.response?.data;
    String errorMessage = "Something went wrong.";
    if (responseData is Map && responseData.containsKey('message')) {
      final msg = responseData['message'];
      if (msg is List) {
        errorMessage = msg.join(', ');
      } else {
        errorMessage = msg.toString();
      }
    } else if (err.message != null && err.message!.isNotEmpty) {
      errorMessage = err.message!;
    }
    return errorMessage;
  }
}
