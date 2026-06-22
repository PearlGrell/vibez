import 'package:flutter/material.dart';

class MonogramPainter extends CustomPainter {
  MonogramPainter(this.letter, this.color);
  final String letter;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 122 * s,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final dx = 61 * s - tp.width / 2;
    final dy = 97 * s - baseline;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(MonogramPainter old) =>
      old.letter != letter || old.color != color;
}
