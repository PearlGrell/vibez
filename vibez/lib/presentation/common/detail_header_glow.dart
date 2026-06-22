import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

class DetailHeaderGlow extends StatelessWidget {
  final String seed;
  final double height;

  const DetailHeaderGlow({
    super.key,
    required this.seed,
    this.height = 320,
  });

  static const List<Color> _palette = [
    Color(0xFF6F64C4),
    Color(0xFFA752A1),
    Color(0xFF3672BE),
    Color(0xFF008DA5),
    Color(0xFF188C87),
    Color(0xFF3B9158),
    Color(0xFF859A33),
    Color(0xFFCD971B),
    Color(0xFFD56927),
    Color(0xFFC74C41),
    Color(0xFFBA4764),
    Color(0xFF4F65A5),
  ];

  static int _hash(String s) {
    int h = 2166136261;
    for (int i = 0; i < s.length; i++) {
      h ^= s.codeUnitAt(i);
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return h >>> 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[_hash(seed) % _palette.length];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.4),
              radius: 1.1,
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.06),
                AppColors.background.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
