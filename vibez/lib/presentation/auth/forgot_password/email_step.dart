import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/auth/widgets/text_field.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class ForgotPasswordEmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSendOtp;

  const ForgotPasswordEmailStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSendOtp,
  });

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
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
            "Forgot Password?",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text(
            "Enter your email and we'll send you a 6-digit OTP code to reset your password.",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: AppSpacing.s4),
          Form(
            key: formKey,
            child: EditText(
              controller: emailController,
              label: "Email",
              hintText: "you@email.com",
              prefixIcon: Icons.alternate_email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
              enabled: !isLoading,
              onSubmitted: (_) => onSendOtp(),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : onSendOtp,
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
                      "Send OTP",
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
