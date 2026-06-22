import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';

class ShuffleTile extends StatelessWidget {
  final VoidCallback onTap;

  const ShuffleTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.hairlineDark,
            width: 0.5,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.card, AppColors.cardAlt],
          ),
        ),
        child: const Center(
          child: Icon(Icons.shuffle_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }
}
