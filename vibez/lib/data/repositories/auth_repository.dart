import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/storage/token_storage.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/services/auth_service.dart';

class AuthRepository {
  static final AuthRepository instance = AuthRepository._();
  late final AuthService _authService;
  late final TokenStorage _tokenStorage;

  AuthRepository._() {
    _authService = AuthService.instance;
    _tokenStorage = TokenStorage.instance;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      await _tokenStorage.setAccessToken(res['token']);
      return true;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final res = await _authService.login(email: email, password: password);
      await _tokenStorage.setAccessToken(res['token']);
      return true;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    try {
      await _authService.forgotPassword(email: email);
      return true;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return false;
    }
  }

  Future<bool> resendOtp({required String email}) async {
    try {
      await _authService.resendOtp(email: email);
      return true;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return false;
    }
  }

  Future<String?> verifyOtp({required String email, required String otp}) async {
    try {
      final res = await _authService.verifyOtp(email: email, otp: otp);
      return res['resetToken'] as String?;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<bool> resetPassword({required String resetToken, required String password}) async {
    try {
      await _authService.resetPassword(resetToken: resetToken, password: password);
      return true;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }
}
