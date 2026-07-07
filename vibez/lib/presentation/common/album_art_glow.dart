import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/utils/image_color.dart';
import 'package:vibez/data/services/audio_reactive_service.dart';

class AlbumArtGlow extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final bool playing;
  final Widget child;

  const AlbumArtGlow({
    super.key,
    required this.imageUrl,
    required this.child,
    this.radius = 16,
    this.playing = false,
  });

  @override
  State<AlbumArtGlow> createState() => _AlbumArtGlowState();
}

class _AlbumArtGlowState extends State<AlbumArtGlow>
    with SingleTickerProviderStateMixin {
  Color? _color;

  late final Ticker _ticker;
  final ValueNotifier<double> _intensity = ValueNotifier(0);

  double _target = 0;
  double _current = 0;
  Duration _lastEvent = Duration.zero;
  Duration _elapsed = Duration.zero;
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = AudioReactiveService.instance.level.listen((v) {
      _target = v;
      _lastEvent = _elapsed;
    });
    _ticker = createTicker(_onTick)..start();
    _extract();
  }

  @override
  void didUpdateWidget(AlbumArtGlow old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) _extract();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.dispose();
    _intensity.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _elapsed = elapsed;

    final reactive = (elapsed - _lastEvent).inMilliseconds < 400;

    double goal;
    if (reactive) {
      goal = _target;
    } else if (widget.playing) {
      final t = elapsed.inMilliseconds / 2400.0;
      goal = 0.15 + 0.2 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
    } else {
      goal = 0;
    }

    _current += (goal - _current) * 0.22;
    if ((_current - _intensity.value).abs() > 0.003) {
      _intensity.value = _current.clamp(0.0, 1.0);
    }
  }

  Future<void> _extract() async {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _color = null);
      return;
    }
    final color = await extractVibrantColor(url);
    if (mounted && url == widget.imageUrl) {
      setState(() => _color = color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color ?? AppColors.primary;
    return ValueListenableBuilder<double>(
      valueListenable: _intensity,
      builder: (context, i, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22 + 0.4 * i),
                blurRadius: 30 + 46 * i,
                spreadRadius: 1 + 14 * i,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
