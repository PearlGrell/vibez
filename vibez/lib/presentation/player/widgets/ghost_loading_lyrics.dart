import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';

class GhostLoadingLyrics extends StatefulWidget {
  const GhostLoadingLyrics({super.key});

  @override
  State<GhostLoadingLyrics> createState() => _GhostLoadingLyricsState();
}

class _GhostLoadingLyricsState extends State<GhostLoadingLyrics>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widths = [0.6, 0.8, 0.5, 0.7, 0.9, 0.4, 0.6, 0.8];

    return FadeTransition(
      opacity: _animation,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s5,
          vertical: AppSpacing.s4,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widths.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widths[index],
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
