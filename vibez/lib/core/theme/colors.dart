import 'dart:ui';
import 'package:vibez/presentation/common/cover_color.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF18181B);
  static const Color card = Color(0xFF27272A);
  static const Color cardAlt = Color(0xFF1F1F23);

  static const Color primary = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFFEC4899);
  static const Color success = Color(0xFF22C55E);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);

  static const Color text = Color(0xFFFAFAFA);
  static const Color text2 = Color(0xFFA1A1AA);
  static const Color text3 = Color(0xFF71717A);

  static const Color hairlineLight = Color(0x12FFFFFF);
  static const Color hairlineDark = Color(0x1EFFFFFF);

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

  static CoverColor generateBgColor(String seed) {
    return _palette[_hashStr(seed) % _palette.length];
  }

  static Color generateTextColor(String seed) {
    return generateBgColor(seed).isLight
        ? const Color(0xB8000000)
        : const Color(0xEBFFFFFF);
  }
}
