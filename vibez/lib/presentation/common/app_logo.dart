import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

enum LogoSize { small, medium, large }

class AppTextLogo extends StatelessWidget {
  final LogoSize size;

  const AppTextLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final double fontSize = switch (size) {
      LogoSize.large => 48.0,
      LogoSize.medium => 36.0,
      LogoSize.small => 24.0,
    };
    final textSize = switch (size) {
      LogoSize.large => Theme.of(context).textTheme.bodyLarge,
      LogoSize.medium => Theme.of(context).textTheme.bodyMedium,
      LogoSize.small => Theme.of(context).textTheme.bodySmall,
    };
    return RichText(
      text: TextSpan(
        text: "vi",
        style: textSize?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        children: [
          TextSpan(
            text: "bez",
            style: TextStyle(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class AppIconLogo extends StatelessWidget {
  final LogoSize size;

  const AppIconLogo({super.key, this.size = LogoSize.medium});

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      LogoSize.small => (24.0, 8.0),
      LogoSize.medium => (36.0, 12.0),
      LogoSize.large => (56.0, 16.0),
    };
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(iconSize.$2),
      child: Image.asset(
        'assets/app_icon.png',
        height: iconSize.$1,
        width: iconSize.$1,
      ),
    );
  }
}
