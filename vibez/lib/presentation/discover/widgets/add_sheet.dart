import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';

class AddSheet extends StatelessWidget {
  const AddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          border: Border.all(
            color: AppColors.hairlineDark
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.text3.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.cardAlt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.text2,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildOptionCard(
                  context: context,
                  icon: Icons.headphones_outlined,
                  title: 'New room',
                  subtitle:
                      'Host a live session — listen together with a DJ, chat, and reactions.',
                  onTap: () {
                    AppRouter.instance.push(RouteLocation.roomAdd);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                
                _buildOptionCard(
                  context: context,
                  icon: Icons.playlist_add,
                  title: 'New playlist',
                  subtitle:
                      'Collect tracks into your own private mix to play anytime.',
                  onTap: () {
                    AppRouter.instance.push(RouteLocation.playlistAdd);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairlineDark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.text,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.text2,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            const Icon(
              Icons.chevron_right,
              color: AppColors.text3,
              size: 20,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
