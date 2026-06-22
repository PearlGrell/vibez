import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class BobbingAlbumArt extends StatefulWidget {
  const BobbingAlbumArt({
    super.key,
    required this.seed,
    required this.index,
    this.size = 110,
    this.radius = 16,
    this.amplitude = 8,
  });

  final String seed;
  final int index;
  final double size;
  final double radius;
  final double amplitude;

  @override
  State<BobbingAlbumArt> createState() => _BobbingAlbumArtState();
}

class _BobbingAlbumArtState extends State<BobbingAlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    final periodMs = ((3.0 + (widget.index % 3) * 0.7) * 1000).round();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: periodMs ~/ 2),
    );
    _y = Tween<double>(
      begin: 0,
      end: -widget.amplitude,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _y,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _y.value), child: child),
      child: AlbumArtCover(
        seed: widget.seed,
        size: widget.size,
        radius: widget.radius,
      ),
    );
  }
}

class AlbumCoverBackground extends StatelessWidget {
  const AlbumCoverBackground({
    super.key,
    this.tile = 120,
    this.gap = 12,
    this.scale = 1.5,
    this.angleDegrees = -8,
  });

  final double tile;
  final double gap;
  final double scale;
  final double angleDegrees;

  @override
  Widget build(BuildContext context) {
    final List<String> seeds = [
      "Abbey Road",
      "Help",
      "Sgt. Pepper Lonely Hearts Club Band",
      "Song Sung Blue",
      "Dust in the Wind",
      "I am... I said",
      "Talat Aziz",
      "Lola Marsh",
      "Simon and Garfunkle",
    ];
    return Stack(
      children: [
        Container(
          color: AppColors.background,
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, c) {
                final cell = tile + gap;

                final cols = (c.maxWidth * scale / cell).ceil() + 2;
                final rows = (c.maxHeight * scale / cell).ceil() + 2;
                final count = cols * rows;

                return Center(
                  child: Transform.rotate(
                    angle: angleDegrees * math.pi / 180,
                    child: Transform.scale(
                      scale: scale,
                      child: OverflowBox(
                        maxWidth: cols * cell,
                        maxHeight: rows * cell,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: count,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: AppSpacing.s3,
                                mainAxisSpacing: AppSpacing.s8,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (_, i) => BobbingAlbumArt(
                            seed: seeds[(i + (i ~/ cols)) % seeds.length],
                            index: i,
                            size: tile,
                            radius: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(color: Colors.black54),
      ],
    );
  }
}
