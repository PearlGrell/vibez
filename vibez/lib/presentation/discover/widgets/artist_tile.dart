import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/core/utils/image_cache_size.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class ArtistTile extends StatelessWidget {
  final SearchArtist artist;
  final VoidCallback onTap;

  const ArtistTile({super.key, required this.artist, required this.onTap});

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
              AlbumArtCover(
                seed: artist.name,
                size: 52,
                radius: 26,
                child: artist.thumbnail.isNotEmpty
                    ? Image.network(
                        artist.thumbnail,
                        width: 52,
                        height: 52,
                        cacheWidth: thumbCacheWidth(context, 52),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: AppTypography.heading3.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Artist',
                      style: AppTypography.small.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.text3,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
