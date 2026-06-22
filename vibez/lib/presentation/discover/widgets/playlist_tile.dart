import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class PlaylistTile extends StatelessWidget {
  final SearchPlaylist playlist;
  final VoidCallback onTap;

  const PlaylistTile({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = playlist.description?.isNotEmpty == true
        ? playlist.description!
        : 'Playlist';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            children: [
              AlbumArtCover(
                seed: playlist.name,
                size: 52,
                radius: AppRadius.xs,
                child: playlist.thumbnail != null &&
                        playlist.thumbnail!.isNotEmpty
                    ? Image.network(
                        playlist.thumbnail!,
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
                      playlist.name,
                      style: AppTypography.heading3.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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
