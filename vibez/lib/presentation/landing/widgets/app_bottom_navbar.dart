import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';

class AppBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Function() buttonTap;

  const AppBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.buttonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: ClipRRect(
        borderRadius: AppRadius.pillBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              borderRadius: AppRadius.pillBorderRadius,
              color: AppColors.surface.withValues(alpha: 0.65),
              border: Border.all(color: AppColors.hairlineLight, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox.shrink(),
                    _item(
                      icon: Icons.explore_outlined,
                      label: "Discover",
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    const SizedBox(width: 96),
                    _item(
                      icon: Icons.person_outline,
                      label: "You",
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),

                Positioned(
                  top: 8,
                  child: GestureDetector(
                    onTap: buttonTap,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: AppShadows.shGlowLg
                      ),
                      child: const Icon(Icons.add, color: AppColors.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.text2, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.text : AppColors.text2,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
