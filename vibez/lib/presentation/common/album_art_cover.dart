import 'package:flutter/material.dart';
import 'package:vibez/presentation/common/cover_color.dart';
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
  static const List<CoverColor> _palette = [
    CoverColor(Color(0xFF6F64C4), Color(0xFF423488), false),
    CoverColor(Color(0xFFA752A1), Color(0xFF6E236A), false),
    CoverColor(Color(0xFF3672BE), Color(0xFF064082), false),
    CoverColor(Color(0xFF008DA5), Color(0xFF005A6E), false),
    CoverColor(Color(0xFF188C87), Color(0xFF005955), false),
    CoverColor(Color(0xFF3B9158), Color(0xFF005D2D), false),
    CoverColor(Color(0xFF859A33), Color(0xFF566600), true),
    CoverColor(Color(0xFFCD971B), Color(0xFF936500), true),
    CoverColor(Color(0xFFD56927), Color(0xFF973A00), true),
    CoverColor(Color(0xFFC74C41), Color(0xFF891915), false),
    CoverColor(Color(0xFFBA4764), Color(0xFF7D1537), false),
    CoverColor(Color(0xFF4F65A5), Color(0xFF25366C), false),
  ];

  static int _hashStr(String s) {
    int h = 2166136261;
    for (int i = 0; i < s.length; i++) {
      h ^= s.codeUnitAt(i);
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return h >>> 0;
  }

  static CoverColor _colorFor(String seed) =>
      _palette[_hashStr(seed) % _palette.length];

  static String _letterFor(String seed) {
    final cleaned = seed.replaceAll(RegExp(r'[@#_]'), ' ').trim();
    return (cleaned.isEmpty ? 'V' : cleaned[0]).toUpperCase();
  }

  static Color ink(String seed) => _colorFor(seed).isLight
      ? const Color(0xB8000000)
      : const Color(0xEBFFFFFF);

  @override
  Widget build(BuildContext context) {
    final c = _colorFor(seed);
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
          ?child,
        ],
      ),
    );
  }
}
