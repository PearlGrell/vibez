import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/image_cache_size.dart';
import 'package:vibez/data/models/playlist.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final double width;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = playlist.thumbnail;
    final count = playlist.songs?.length;
    final creator = playlist.createdBy?.name;
    final subtitle = count != null
        ? '$count ${count == 1 ? 'song' : 'songs'}'
        : (creator != null ? 'By $creator' : 'Playlist');

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: AppRadius.mdBorderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AlbumArtCover(
                      seed: playlist.name,
                      size: width,
                      radius: AppRadius.md,
                      child: thumb != null && thumb.isNotEmpty
                          ? Image.network(
                              thumb,
                              cacheWidth: thumbCacheWidth(context, width),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            )
                          : null,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.queue_music_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.text2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
