import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';

class PasswordNotifier extends StatelessWidget {
  const PasswordNotifier({super.key, required this.password});

  final String password;

  int get strength => _calculateStrength(password);

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);

    final color = switch (strength) {
      1 => const Color(0xFFFF4D7D),
      2 => const Color(0xFFFFB84D),
      3 => const Color(0xFF22C55E),
      _ => Colors.transparent,
    };

    final label = switch (strength) {
      1 => 'Weak',
      2 => 'Medium',
      3 => 'Strong',
      _ => '',
    };

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.s2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index == 2 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: index < strength
                          ? color
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ),
           SizedBox(width: AppSpacing.s2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateStrength(String password) {
    int score = 0;

    if (password.length >= 6) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 1) return 1;
    if (score <= 3) return 2;
    return 3;
  }
}
