import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/auth/widgets/text_field.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class ForgotPasswordOtpStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final String email;
  final bool isLoading;
  final VoidCallback onVerifyOtp;
  final Future<bool> Function() onResendOtp;

  const ForgotPasswordOtpStep({
    super.key,
    required this.formKey,
    required this.otpController,
    required this.email,
    required this.isLoading,
    required this.onVerifyOtp,
    required this.onResendOtp,
  });

  @override
  State<ForgotPasswordOtpStep> createState() => _ForgotPasswordOtpStepState();
}

class _ForgotPasswordOtpStepState extends State<ForgotPasswordOtpStep> {
  int _secondsRemaining = 0;
  int _resendCount = 0;
  Timer? _timer;

  final List<int> _cooldownTimes = [60, 120, 300, 600, 1800];

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    final int cooldownSeconds = _resendCount < _cooldownTimes.length
        ? _cooldownTimes[_resendCount]
        : 1800;

    setState(() {
      _secondsRemaining = cooldownSeconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;
    if (_resendCount >= 5) {
      return;
    }
    final success = await widget.onResendOtp();
    if (success) {
      setState(() {
        _resendCount++;
      });
      _startCooldown();
    }
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    final String secondsStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minutes:$secondsStr';
  }

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    final otp = value.trim();
    if (otp.length != 6) {
      return 'OTP must be exactly 6 digits';
    }
    if (int.tryParse(otp) == null) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s2,
        children: [
          const SizedBox(height: AppSpacing.s3),
          const AppIconLogo(size: LogoSize.large),
          const SizedBox(height: AppSpacing.s1 / 2),
          Text("Verify Code", style: Theme.of(context).textTheme.displayMedium),
          Text(
            "Enter the 6-digit OTP code we sent to ${widget.email}.",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: AppSpacing.s4),
          Form(
            key: widget.formKey,
            child: EditText(
              controller: widget.otpController,
              label: "OTP Code",
              hintText: "123456",
              prefixIcon: Icons.security_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              validator: _validateOtp,
              enabled: !widget.isLoading,
              onSubmitted: (_) => widget.onVerifyOtp(),
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Haven't received it?"),
              TextButton(
                onPressed: (_secondsRemaining > 0 || _resendCount >= 5)
                    ? null
                    : _handleResend,
                child: Text(
                  _resendCount >= 5
                      ? "Max attempts reached"
                      : (_secondsRemaining > 0
                            ? "Resend in ${_formatTime(_secondsRemaining)}"
                            : "Resend Code"),
                  style: TextStyle(
                    color: (_secondsRemaining > 0 || _resendCount >= 5)
                        ? AppColors.text3
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: widget.isLoading ? null : widget.onVerifyOtp,
              child: widget.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.text,
                      ),
                    )
                  : Text(
                      "Verify OTP",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
