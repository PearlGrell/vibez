import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

Future<Color?> extractVibrantColor(String url, {int sample = 32}) async {
  try {
    final provider = ResizeImage(
      NetworkImage(url),
      width: sample,
      height: sample,
    );
    final image = await _resolve(provider);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) return null;

    final bytes = data.buffer.asUint8List();
    double rSum = 0, gSum = 0, bSum = 0, wSum = 0;
    for (int i = 0; i + 3 < bytes.length; i += 4) {
      final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2], a = bytes[i + 3];
      if (a < 128) continue;
      final maxc = math.max(r, math.max(g, b));
      final minc = math.min(r, math.min(g, b));
      final sat = maxc == 0 ? 0.0 : (maxc - minc) / maxc;
      final val = maxc / 255.0;

      final w = sat * sat * (1.0 - (val - 0.6).abs() * 1.4);
      if (w <= 0) continue;
      rSum += r * w;
      gSum += g * w;
      bSum += b * w;
      wSum += w;
    }
    if (wSum <= 0) return null;

    var color = Color.fromARGB(
      255,
      (rSum / wSum).round().clamp(0, 255),
      (gSum / wSum).round().clamp(0, 255),
      (bSum / wSum).round().clamp(0, 255),
    );

    final hsl = HSLColor.fromColor(color);
    color = hsl
        .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
        .withLightness(hsl.lightness.clamp(0.35, 0.6))
        .toColor();
    return color;
  } catch (_) {
    return null;
  }
}

Future<ui.Image> _resolve(ImageProvider provider) {
  final completer = Completer<ui.Image>();
  final stream = provider.resolve(const ImageConfiguration());
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image);
      stream.removeListener(listener);
    },
    onError: (Object e, StackTrace? s) {
      if (!completer.isCompleted) completer.completeError(e);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
