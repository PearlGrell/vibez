import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/data/models/recent_item.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class GridTile extends StatelessWidget {
  final RecentItem item;
  final bool isPlaying;
  final VoidCallback onTap;

  const GridTile({
    super.key,
    required this.item,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isPlaying ? AppColors.primary : Colors.transparent,
            width: isPlaying ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AlbumArtCover(
                seed: item.name,
                size: 200,
                radius: AppRadius.sm,
                child: item.thumbnail != null && item.thumbnail!.isNotEmpty
                    ? Image.network(
                        item.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.type != RecentItemType.song && !isPlaying)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _iconFor(item.type),
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(RecentItemType type) {
    switch (type) {
      case RecentItemType.album:
        return Icons.album_rounded;
      case RecentItemType.playlist:
        return Icons.queue_music_rounded;
      case RecentItemType.artist:
        return Icons.person_rounded;
      case RecentItemType.song:
        return Icons.music_note_rounded;
    }
  }
}
