import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/discover/widgets/section_header.dart';

/// A titled section with a horizontally scrolling row of cards.
class HorizontalSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final Widget? trailing;
  final double height;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const HorizontalSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accent,
    this.trailing,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          accent: accent,
          trailing: trailing,
        ),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}

/// Placeholder row shown while a section is loading.
class LoadingRow extends StatelessWidget {
  final double itemWidth;
  final double itemHeight;
  final int count;

  const LoadingRow({
    super.key,
    required this.itemWidth,
    required this.itemHeight,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
        itemBuilder: (_, _) => Container(
          width: itemWidth,
          decoration: BoxDecoration(
            color: AppColors.cardAlt.withValues(alpha: 0.5),
            borderRadius: AppRadius.mdBorderRadius,
          ),
        ),
      ),
    );
  }
}
