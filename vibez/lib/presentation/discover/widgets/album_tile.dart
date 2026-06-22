import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class AlbumTile extends StatelessWidget {
  final SearchAlbum album;
  final VoidCallback onTap;

  const AlbumTile({super.key, required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeStr = album.type.isNotEmpty ? album.type : 'Album';
    final meta = album.year.isNotEmpty
        ? '${album.artists} · $typeStr · ${album.year}'
        : '${album.artists} · $typeStr';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            children: [
              AlbumArtCover(
                seed: album.title,
                size: 52,
                radius: AppRadius.xs,
                child: album.thumbnail.isNotEmpty
                    ? Image.network(
                        album.thumbnail,
                        width: 52,
                        height: 52,
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
                      album.title,
                      style: AppTypography.heading3.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: AppTypography.small.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
