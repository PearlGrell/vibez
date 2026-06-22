import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/auth/register/credentials_step.dart';
import 'package:vibez/presentation/auth/register/username_step.dart';
import 'package:vibez/presentation/auth/register/customize_profile_step.dart';
import 'package:vibez/presentation/auth/widgets/password_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  final _pageController = PageController();

  bool _isLoading = false;
  int stage = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (PasswordNotifier(password: _passwordController.text).strength < 2) {
      AppSnackbar.show(
        message:
            "Please choose a stronger password. Use at least 8 characters, including a number and a special character.",
        type: AppSnackType.warning,
      );
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(userProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        stage = 1;
      });
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      stage = 1;
      _pageController.jumpToPage(stage);
    });
  }

  Future<void> _handleUpdateUsername() async {
    if (!_usernameFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(userProvider.notifier).updateProfile({
      'username': _usernameController.text.trim(),
    });

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        stage = 2;
      });
      _pageController.jumpToPage(2);
    }
  }

  void _handleFinish() {
    AppRouter.instance.go(RouteLocation.discover);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(userProvider) != null;
    return PopScope(
      canPop: stage == 0,
      onPopInvokedWithResult: (didPop, res) {
        if (didPop) return;
        if (isLoggedIn) {
          AppRouter.instance.go(RouteLocation.discover);
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
                if (isLoggedIn) {
                  AppRouter.instance.go(RouteLocation.discover);
                } else {
                  AppRouter.instance.pop();
                }
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
            CredentialsStep(
              formKey: _formKey,
              nameController: _nameController,
              emailController: _emailController,
              passwordController: _passwordController,
              isLoading: _isLoading,
              onRegister: _handleRegister,
            ),
            UsernameStep(
              usernameFormKey: _usernameFormKey,
              usernameController: _usernameController,
              isLoading: _isLoading,
              onUpdateUsername: _handleUpdateUsername,
            ),
            CustomizeProfileStep(onFinish: _handleFinish),
          ],
        ),
        bottomNavigationBar: stage == 0
            ? Container(
                height: kBottomNavigationBarHeight,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.text3, width: 0.75),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have one?"),
                    TextButton(
                      onPressed: () {
                        AppRouter.instance.push(RouteLocation.login);
                      },
                      child: const Text("Log in"),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
