import 'package:flutter/material.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/repositories/auth_repository.dart';
import 'package:vibez/presentation/auth/forgot_password/email_step.dart';
import 'package:vibez/presentation/auth/forgot_password/otp_step.dart';
import 'package:vibez/presentation/auth/forgot_password/reset_step.dart';
import 'package:vibez/presentation/auth/widgets/password_notifier.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _pageController = PageController();

  bool _isLoading = false;
  int stage = 0;
  String _email = '';
  String _resetToken = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final targetEmail = _emailController.text.trim();
    final success = await AuthRepository.instance.forgotPassword(email: targetEmail);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _email = targetEmail;
        stage = 1;
      });
      _pageController.jumpToPage(1);
    }
  }

  Future<bool> _handleResendOtp() async {
    setState(() {
      _isLoading = true;
    });

    final success = await AuthRepository.instance.resendOtp(email: _email);

    if (!mounted) return false;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      AppSnackbar.show(
        message: "A new OTP reset code has been sent.",
        type: AppSnackType.success,
      );
    }
    return success;
  }

  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = await AuthRepository.instance.verifyOtp(
      email: _email,
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (token != null) {
      setState(() {
        _resetToken = token;
        stage = 2;
      });
      _pageController.jumpToPage(2);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_resetFormKey.currentState!.validate()) {
      return;
    }

    if (PasswordNotifier(password: _passwordController.text).strength < 2) {
      AppSnackbar.show(
        message: "Please choose a stronger password.",
        type: AppSnackType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await AuthRepository.instance.resetPassword(
      resetToken: _resetToken,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      AppSnackbar.show(
        message: "Password reset successfully. You can now log in.",
        type: AppSnackType.success,
      );
      AppRouter.instance.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: stage == 0,
      onPopInvokedWithResult: (didPop, res) {
        if (didPop) return;
        if (stage > 0) {
          setState(() {
            stage--;
          });
          _pageController.jumpToPage(stage);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.card,
              side: const BorderSide(color: AppColors.text3, width: 0.5),
            ),
            onPressed: () {
              if (stage == 0) {
                AppRouter.instance.pop();
              } else {
                setState(() {
                  stage--;
                });
                _pageController.jumpToPage(stage);
              }
            },
            icon: const Icon(Icons.chevron_left),
          ),
          title: Flex(
            direction: Axis.horizontal,
            spacing: AppSpacing.s1,
            children: [
              Flexible(
                flex: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: stage >= 0 ? AppColors.primary : AppColors.text3,
                    borderRadius: AppRadius.pillBorderRadius,
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: stage >= 1 ? AppColors.primary : AppColors.text3,
                    borderRadius: AppRadius.pillBorderRadius,
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  decoration: BoxDecoration(
                    color: stage >= 2 ? AppColors.primary : AppColors.text3,
                    borderRadius: AppRadius.pillBorderRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ForgotPasswordEmailStep(
              formKey: _emailFormKey,
              emailController: _emailController,
              isLoading: _isLoading,
              onSendOtp: _handleSendOtp,
            ),
            ForgotPasswordOtpStep(
              formKey: _otpFormKey,
              otpController: _otpController,
              email: _email,
              isLoading: _isLoading,
              onVerifyOtp: _handleVerifyOtp,
              onResendOtp: _handleResendOtp,
            ),
            ForgotPasswordResetStep(
              formKey: _resetFormKey,
              passwordController: _passwordController,
              confirmPasswordController: _confirmPasswordController,
              isLoading: _isLoading,
              onResetPassword: _handleResetPassword,
            ),
          ],
        ),
      ),
    );
  }
}
