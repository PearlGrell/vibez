import 'package:flutter/material.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/common/skeleton.dart';

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (int i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                const Skeleton(height: 52, width: 52, borderRadius: 8),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(height: 14, width: 150, borderRadius: 4),
                      SizedBox(height: 8),
                      Skeleton(height: 11, width: 100, borderRadius: 3),
                    ],
                  ),
                ),
                const Skeleton(height: 20, width: 20, borderRadius: 10),
                const SizedBox(width: 16),
                const Skeleton(height: 20, width: 20, borderRadius: 10),
              ],
            ),
          ),
      ],
    );
  }
}
