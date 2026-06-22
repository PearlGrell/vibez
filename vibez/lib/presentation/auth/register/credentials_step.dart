import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/auth/widgets/password_notifier.dart';
import 'package:vibez/presentation/auth/widgets/text_field.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class CredentialsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onRegister;

  const CredentialsStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onRegister,
  });

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
            "Create your account",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text(
            "Set up your handle and start a room in seconds.",
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
                  controller: nameController,
                  label: "Name",
                  hintText: "John Doe",
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  enabled: !isLoading,
                ),
                EditText(
                  controller: emailController,
                  label: "Email",
                  hintText: "you@email.com",
                  prefixIcon: Icons.alternate_email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  enabled: !isLoading,
                ),
                EditText(
                  controller: passwordController,
                  label: "Password",
                  hintText: "••••••••",
                  prefixIcon: Icons.password_outlined,
                  password: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  enabled: !isLoading,
                  onSubmitted: (_) => onRegister(),
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
          const SizedBox(height: AppSpacing.s2),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onRegister,
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
                      "Create account",
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
