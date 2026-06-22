import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/auth/widgets/text_field.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(userProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      AppRouter.instance.go(RouteLocation.discover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.card,
            side: const BorderSide(color: AppColors.text3, width: 0.5),
          ),
          onPressed: () => AppRouter.instance.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.s2,
            children: [
              const SizedBox(height: AppSpacing.s3),
              const AppIconLogo(size: LogoSize.large),
              const SizedBox(height: AppSpacing.s1/2),
              Text(
                "Welcome back",
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Text(
                "Log in to pick up where the night fell off.",
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.text2),
              ),
              const SizedBox(height: AppSpacing.s4),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: AppSpacing.s3,
                  children: [
                    EditText(
                      controller: _emailController,
                      label: "Email",
                      hintText: "you@email.com",
                      prefixIcon: Icons.alternate_email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    EditText(
                      controller: _passwordController,
                      label: "Password",
                      hintText: "••••••••",
                      prefixIcon: Icons.password_outlined,
                      password: true,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    GestureDetector(
                      onTap: () {
                        AppRouter.instance.push(RouteLocation.forgotPassword);
                      },
                      child: Text(
                        "Forgot Password?",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.text,
                          ),
                        )
                      : Text(
                          "Log in",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: kBottomNavigationBarHeight,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.text3, width: 0.75)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("New here?"),
            TextButton(onPressed: () {
              AppRouter.instance.push(RouteLocation.register);
            }, child: const Text("Create account")),
          ],
        ),
      ),
    );
  }
}
