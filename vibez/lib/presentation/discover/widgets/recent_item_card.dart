import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/image_cache_size.dart';
import 'package:vibez/data/models/recent_item.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

/// A recently played album or artist card. Artists render as a circle.
class RecentItemCard extends StatelessWidget {
  final RecentItem item;
  final VoidCallback onTap;
  final double width;

  const RecentItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    final isArtist = item.type == RecentItemType.artist;
    final thumb = item.thumbnail;
    final radius = isArtist ? AppRadius.pill : AppRadius.md;
    final align = isArtist
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: align,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AlbumArtCover(
                      seed: item.name,
                      size: width,
                      radius: radius,
                      child: thumb != null && thumb.isNotEmpty
                          ? Image.network(
                              thumb,
                              cacheWidth: thumbCacheWidth(context, width),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            )
                          : null,
                    ),
                    if (!isArtist)
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
                            Icons.album_rounded,
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
              item.name,
              textAlign: isArtist ? TextAlign.center : TextAlign.start,
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
              isArtist ? 'Artist' : 'Album',
              textAlign: isArtist ? TextAlign.center : TextAlign.start,
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
