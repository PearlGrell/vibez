import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/auth/widgets/password_notifier.dart';
import 'package:vibez/presentation/auth/widgets/text_field.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class ForgotPasswordResetStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onResetPassword;

  const ForgotPasswordResetStep({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onResetPassword,
  });

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
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
          Text(
            "New Password",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text(
            "Create a new password. Make sure it's strong and secure.",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: AppSpacing.s4),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: AppSpacing.s3,
              children: [
                EditText(
                  controller: passwordController,
                  label: "New Password",
                  hintText: "••••••••",
                  prefixIcon: Icons.password_outlined,
                  password: true,
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                  enabled: !isLoading,
                ),
                EditText(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  hintText: "••••••••",
                  prefixIcon: Icons.password_outlined,
                  password: true,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  enabled: !isLoading,
                  onSubmitted: (_) => onResetPassword(),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: passwordController,
            builder: (context, value, child) {
              return PasswordNotifier(password: value.text);
            },
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : onResetPassword,
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.text,
                      ),
                    )
                  : Text(
                      "Reset Password",
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
