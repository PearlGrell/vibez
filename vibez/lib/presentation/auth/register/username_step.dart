import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/repositories/user_repository.dart';
import 'package:vibez/presentation/auth/widgets/text_field.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class UsernameStep extends StatefulWidget {
  final GlobalKey<FormState> usernameFormKey;
  final TextEditingController usernameController;
  final bool isLoading;
  final VoidCallback onUpdateUsername;

  const UsernameStep({
    super.key,
    required this.usernameFormKey,
    required this.usernameController,
    required this.isLoading,
    required this.onUpdateUsername,
  });

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<UsernameStep> {
  Timer? _debounceTimer;
  bool _isChecking = false;
  bool? _isAvailable;

  @override
  void initState() {
    super.initState();
    widget.usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    widget.usernameController.removeListener(_onUsernameChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged() {
    final text = widget.usernameController.text.trim();
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      setState(() {
        _isChecking = false;
        _isAvailable = null;
      });
      return;
    }

    if (text.length < 3 || text.length > 16) {
      setState(() {
        _isChecking = false;
        _isAvailable = null;
      });
      return;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!usernameRegex.hasMatch(text)) {
      setState(() {
        _isChecking = false;
        _isAvailable = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _isAvailable = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        final available = await UserRepository.instance.checkUsername(text);
        if (!mounted) return;
        setState(() {
          _isChecking = false;
          _isAvailable = available;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isChecking = false;
          _isAvailable = null;
        });
      }
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final text = value.trim();
    if (text.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (text.length > 16) {
      return 'Username must be at most 16 characters';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!usernameRegex.hasMatch(text)) {
      return 'Only letters, numbers, underscores, and dots are allowed';
    }
    if (_isAvailable == false) {
      return 'Username is already taken';
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
            "Claim your handle",
            style: Theme.of(context).textTheme.displayMedium,
          ),
          Text(
            "This is how friends find you in rooms and chat.",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: AppSpacing.s4),
          Form(
            key: widget.usernameFormKey,
            child: EditText(
              controller: widget.usernameController,
              label: "Username",
              hintText: "username",
              prefixIcon: Icons.alternate_email,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              validator: _validateUsername,
              enabled: !widget.isLoading,
              onSubmitted: (_) {
                if (!_isChecking && _isAvailable != false) {
                  widget.onUpdateUsername();
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s1 / 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("3-16 characters · letters, numbers, underscores"),
              if (_isChecking)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else if (_isAvailable == true)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
              else if (_isAvailable == false)
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 16),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: (widget.isLoading || _isChecking || _isAvailable == false)
                  ? null
                  : widget.onUpdateUsername,
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
                      "Continue",
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
