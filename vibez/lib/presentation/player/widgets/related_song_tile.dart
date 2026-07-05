import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/image_cache_size.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class RelatedSongTile extends StatelessWidget {
  final Song song;
  final String Function(int) formatDuration;
  final VoidCallback onTap;
  final VoidCallback onAddToQueue;

  const RelatedSongTile({
    super.key,
    required this.song,
    required this.formatDuration,
    required this.onTap,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s2 + 2,
          ),
          child: Row(
            children: [
              AlbumArtCover(
                seed: song.title,
                size: 44,
                radius: AppRadius.xs,
                child: song.thumbnail != null && song.thumbnail!.isNotEmpty
                    ? Image.network(
                        song.thumbnail!,
                        cacheWidth: thumbCacheWidth(context, 44),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artists?.map((e) => e.name).join(', ') ??
                          'Unknown Artist',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.text2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              GestureDetector(
                onTap: onAddToQueue,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.text3,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
