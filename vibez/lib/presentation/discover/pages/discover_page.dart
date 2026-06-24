import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/recent_item.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/presentation/discover/widgets/recent_grid.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  static List<RecentItem>? _cachedGridItems;
  static List<Song>? _cachedSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final recentItems = playback.recentItems;
    final recentSongs = playback.recentlyPlayed;
    final currentSongId = playback.currentSong?.id;

    if (recentItems.isEmpty && recentSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_rounded,
              size: 56,
              color: AppColors.text3.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text('Play something to get started', style: AppTypography.small),
          ],
        ),
      );
    }

    _cachedGridItems ??= _buildGridItems(recentItems, recentSongs);
    _cachedSongs ??= List.unmodifiable(recentSongs);
    final gridItems = _cachedGridItems!;

    return RefreshIndicator(
      onRefresh: () async {
        _cachedGridItems = null;
        _cachedSongs = null;
      },
      color: AppColors.primary,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(top: AppSpacing.s2, bottom: AppSpacing.s9),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          child: Text('Recently Played', style: AppTypography.heading2),
        ),
        const SizedBox(height: AppSpacing.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          child: RecentGrid(
            items: gridItems,
            currentSongId: currentSongId,
            allSongs: recentSongs,
            onPlay: (item) => _onItemTap(context, ref, item, _cachedSongs!),
            onShuffle: () => _onShuffle(ref, _cachedSongs!),
          ),
        ),
      ],
    ),
    );
  }

  List<RecentItem> _buildGridItems(
    List<RecentItem> recentItems,
    List<Song> recentSongs,
  ) {
    final seen = <String>{};
    final items = <RecentItem>[];

    for (final item in recentItems) {
      final key = '${item.type.name}_${item.id}';
      if (seen.add(key) && items.length < 8) {
        items.add(item);
      }
    }

    for (final song in recentSongs) {
      final key = 'song_${song.id}';
      if (seen.add(key) && items.length < 8) {
        items.add(
          RecentItem(
            id: song.id,
            name: song.title,
            thumbnail: song.thumbnail,
            type: RecentItemType.song,
          ),
        );
      }
    }

    return items;
  }

  void _onItemTap(
    BuildContext context,
    WidgetRef ref,
    RecentItem item,
    List<Song> recentSongs,
  ) {
    if (item.type == RecentItemType.song) {
      final song = recentSongs.firstWhere(
        (s) => s.id == item.id,
        orElse: () => Song(
          id: item.id,
          title: item.name,
          duration: 0,
          thumbnail: item.thumbnail,
        ),
      );
      ref.read(playbackProvider.notifier).playSong(song);
    } else {
      context.push(item.routePath);
    }
  }

  void _onShuffle(WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return;
    final rng = Random();
    final song = songs[rng.nextInt(songs.length)];
    ref.read(playbackProvider.notifier).playSong(song);
  }
}
