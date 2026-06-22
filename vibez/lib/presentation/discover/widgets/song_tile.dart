import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class SongTile extends StatelessWidget {
  final SearchSong song;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onMore;
  final bool isLiked;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onLike,
    required this.onMore,
    this.isLiked = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            children: [
              Stack(
                children: [
                  AlbumArtCover(
                    seed: song.title,
                    size: 52,
                    radius: AppRadius.xs,
                    child: song.thumbnail.isNotEmpty
                        ? Image.network(
                            song.thumbnail,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink(),
                          )
                        : null,
                  ),
                  if (isPlaying)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const Icon(
                          Icons.equalizer_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppTypography.heading3.copyWith(
                        fontSize: 15,
                        color: isPlaying ? AppColors.primary : AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${song.artists} · ${_fmt(song.duration)}',
                      style: AppTypography.small.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onLike,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_outline,
                    color: isLiked ? AppColors.danger : AppColors.text3,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onMore,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.text3,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int s) {
    final m = s ~/ 60;
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }
}
