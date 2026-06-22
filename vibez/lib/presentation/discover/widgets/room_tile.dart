import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class RoomTile extends StatelessWidget {
  final SearchRoom room;
  final VoidCallback onTap;

  const RoomTile({super.key, required this.room, required this.onTap});

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
                seed: room.name,
                size: 52,
                radius: 26,
                child: Icon(
                  Icons.headphones_rounded,
                  color: AlbumArtCover.ink(room.name),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (room.playing)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.equalizer_rounded,
                              color: AppColors.primary,
                              size: 14,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            room.name,
                            style:
                                AppTypography.heading3.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.description.isNotEmpty ? room.description : 'Room',
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
