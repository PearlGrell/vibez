import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

class EqualizerBars extends StatefulWidget {
  final Color? color;

  const EqualizerBars({
    super.key,
    this.color,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _barCount = 3;
  static const _durations = [600, 450, 520];
  static const _minHeights = [0.25, 0.35, 0.2];
  static const _maxHeights = [0.9, 0.7, 1.0];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      )..repeat(reverse: true);
    });
    _animations = List.generate(_barCount, (i) {
      return Tween<double>(
        begin: _minHeights[i],
        end: _maxHeights[i],
      ).animate(CurvedAnimation(
        parent: _controllers[i],
        curve: Curves.easeInOut,
      ));
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_barCount, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, _) {
            return Container(
              width: 3,
              height: 14 * _animations[i].value,
              margin: EdgeInsets.only(right: i < _barCount - 1 ? 2 : 0),
              decoration: BoxDecoration(
                color: widget.color ?? AppColors.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          },
        );
      }),
    );
  }
}
