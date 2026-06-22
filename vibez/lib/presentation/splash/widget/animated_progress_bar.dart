import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.pillBorderRadius,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: 200 * progress,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.pillBorderRadius,
          ),
        ),
      ),
    );
  }
}
