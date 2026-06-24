import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

class EqualizerBars extends StatefulWidget {
  final Color color;
  final double size;
  final int barCount;
  final double barWidth;
  final double barSpacing;

  const EqualizerBars({
    super.key,
    this.color = AppColors.primary,
    this.size = 20,
    this.barCount = 3,
    this.barWidth = 3,
    this.barSpacing = 2,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  final _random = Random();

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(widget.barCount, (_) {
      return AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: 350 + _random.nextInt(450),
        ),
      )..repeat(reverse: true);
    });

    _animations = List.generate(widget.barCount, (i) {
      final minHeight = 0.15 + _random.nextDouble() * 0.35;
      final maxHeight = 0.60 + _random.nextDouble() * 0.40;

      return Tween<double>(
        begin: minHeight,
        end: maxHeight.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(
          parent: _controllers[i],
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxBarHeight = widget.size * 0.8;

    return SizedBox(
      height: widget.size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              return Container(
                width: widget.barWidth,
                height: maxBarHeight * _animations[i].value,
                margin: EdgeInsets.only(
                  right: i == widget.barCount - 1
                      ? 0
                      : widget.barSpacing,
                ),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius:
                      BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}