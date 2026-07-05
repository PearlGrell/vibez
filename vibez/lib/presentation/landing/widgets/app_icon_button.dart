import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final VoidCallback? onLongPress;
  final Color? iconColor;
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onLongPress,
    this.iconSize = 24,
    this.iconColor,
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
          child: GestureDetector(
            onLongPress:onLongPress,
            onTap: onTap,
            behavior: .opaque,
            child: Icon(icon, color: iconColor ?? AppColors.text2, size: iconSize),
          ),
        ),
      ),
    );
  }
}
