import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'skeleton.dart';

class DetailsSkeleton extends StatelessWidget {
  final bool isArtist;
  const DetailsSkeleton({super.key, this.isArtist = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              Align(
                alignment: Alignment.centerLeft,
                child: const Skeleton(height: 40, width: 40, borderRadius: 20),
              ),
              const SizedBox(height: 24),

              Skeleton(
                height: 180,
                width: 180,
                borderRadius: isArtist ? 90 : 12,
              ),
              const SizedBox(height: 24),

              const Skeleton(height: 32, width: 200, borderRadius: 6),
              const SizedBox(height: 12),

              const Skeleton(height: 16, width: 120, borderRadius: 4),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Skeleton(height: 36, width: 36, borderRadius: 18),
                  if (isArtist) ...[
                    const SizedBox(width: 12),
                    const Skeleton(height: 36, width: 80, borderRadius: 18),
                  ],
                  const Spacer(),
                  const Skeleton(height: 56, width: 56, borderRadius: 28),
                ],
              ),
              const SizedBox(height: 32),

              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      const Skeleton(height: 20, width: 20, borderRadius: 4),
                      const SizedBox(width: 16),
                      const Skeleton(height: 50, width: 50, borderRadius: 8),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Skeleton(
                              height: 16,
                              width: 140,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 8),
                            const Skeleton(
                              height: 12,
                              width: 80,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const Skeleton(height: 24, width: 24, borderRadius: 12),
                      const SizedBox(width: 16),
                      const Skeleton(height: 24, width: 24, borderRadius: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
