import 'package:vibez/core/network/api_client.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  late final ApiClient _apiClient;

  AuthService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _apiClient.post(endpoint: '/auth/register', body: {
      "name": name,
      "email": email,
      "password": password,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _apiClient.post(endpoint: '/auth/login', body: {
      "email": email,
      "password": password,
    });
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return _apiClient.post(endpoint: '/auth/forgot', body: {
      "email": email,
    });
  }

  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    return _apiClient.post(endpoint: '/auth/forgot/resend', body: {
      "email": email,
    });
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return _apiClient.post(endpoint: '/auth/verify', body: {
      "email": email,
      "otp": otp,
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
  }) async {
    return _apiClient.post(endpoint: '/auth/reset', body: {
      "resetToken": resetToken,
      "password": password,
    });
  }
}
