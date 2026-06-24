import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(6),
        child: Material(
          color: AppColors.surface,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.hairlineDark),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Icon(icon, color: AppColors.text2, size: iconSize),
          ),
        ),
      ),
    );
  }
}
