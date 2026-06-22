import 'package:flutter/material.dart' hide GridTile;
import 'package:vibez/data/models/recent_item.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/presentation/discover/widgets/grid_tile.dart';
import 'package:vibez/presentation/discover/widgets/shuffle_tile.dart';

class RecentGrid extends StatelessWidget {
  final List<RecentItem> items;
  final String? currentSongId;
  final List<Song> allSongs;
  final void Function(RecentItem) onPlay;
  final VoidCallback onShuffle;

  const RecentGrid({
    super.key,
    required this.items,
    required this.currentSongId,
    required this.allSongs,
    required this.onPlay,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: (items.length + 1).clamp(0, 9),
      itemBuilder: (context, index) {
        if (index == items.length || index == 8) {
          return ShuffleTile(onTap: onShuffle);
        }

        final item = items[index];
        final isPlaying =
            item.type == RecentItemType.song && item.id == currentSongId;

        return GridTile(
          item: item,
          isPlaying: isPlaying,
          onTap: () => onPlay(item),
        );
      },
    );
  }
}
