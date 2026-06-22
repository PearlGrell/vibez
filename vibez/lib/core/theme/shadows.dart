import 'package:flutter/painting.dart';
import 'colors.dart';

class AppShadows {
  AppShadows._();

  static final List<BoxShadow> shSm = [
    BoxShadow(
      color: const Color(0x1F000000),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0x0A000000),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shMd = [
    BoxShadow(
      color: const Color(0x3D000000),
      offset: const Offset(0, 6),
      blurRadius: 20,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: const Color(0x1F000000),
      offset: const Offset(0, 12),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shLg = [
    BoxShadow(
      color: const Color(0x52000000),
      offset: const Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: const Color(0x29000000),
      offset: const Offset(0, 24),
      blurRadius: 48,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shGlowLg = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      offset: const Offset(0, 6),
      blurRadius: 18,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.15),
      offset: const Offset(0, 12),
      blurRadius: 28,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shGlowMd = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 9,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.15),
      blurRadius: 18,
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> shGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.15),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
}
