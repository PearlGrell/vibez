import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/presentation/common/monogram_painter.dart';

class AlbumArtCover extends StatelessWidget {
  const AlbumArtCover({
    super.key,
    required this.seed,
    this.size = 150,
    this.radius = 16,
    this.glow = false,
    this.child,
  });

  final String seed;
  final double size;
  final double radius;
  final bool glow;

  final Widget? child;

  static String _letterFor(String seed) {
    final cleaned = seed.replaceAll(RegExp(r'[@#_]'), ' ').trim();
    return (cleaned.isEmpty ? 'V' : cleaned[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.generateBgColor(seed);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: MonogramPainter(_letterFor(seed), c.mono)),
          if (child != null) child!,
        ],
      ),
    );
  }
}
