import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/models/recent_item.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/discover_provider.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/discover/widgets/horizontal_section.dart';
import 'package:vibez/presentation/discover/widgets/playlist_card.dart';
import 'package:vibez/presentation/discover/widgets/recent_item_card.dart';
import 'package:vibez/presentation/discover/widgets/room_card.dart';
import 'package:vibez/presentation/discover/widgets/section_header.dart';
import 'package:vibez/presentation/discover/widgets/song_card.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  static const double _roomRowHeight = 200;
  static const double _squareRowHeight = 204;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final recentSongs = playback.recentlyPlayed;
    final recentItems = playback.recentItems;
    final currentSongId = playback.currentSong?.id;

    final myRooms = _myLiveRooms(ref);
    final recentAlbums = _itemsOfType(recentItems, RecentItemType.album);
    final recentArtists = _itemsOfType(recentItems, RecentItemType.artist);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(trendingRoomsProvider);
        ref.invalidate(trendingPlaylistsProvider);
        await ref.read(userProvider.notifier).fetchMyRooms();
      },
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.s2,
          bottom: AppSpacing.s9,
        ),
        children: [
          if (myRooms.isNotEmpty) ...[
            HorizontalSection(
              title: 'Your Rooms',
              subtitle: 'Jump back into your live sessions',
              icon: Icons.sensors_rounded,
              height: _roomRowHeight,
              itemCount: myRooms.length,
              itemBuilder: (context, index) {
                final room = myRooms[index];
                return RoomCard(
                  room: room,
                  onTap: () => context.push('/room/${room.id}'),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s6),
          ],
          _TrendingRoomsSection(rowHeight: _roomRowHeight),
          const SizedBox(height: AppSpacing.s6),
          _TrendingPlaylistsSection(rowHeight: _squareRowHeight),
          if (recentSongs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            HorizontalSection(
              title: 'Recently Played',
              subtitle: 'Pick up where you left off',
              icon: Icons.history_rounded,
              height: _squareRowHeight,
              trailing: _ShuffleButton(
                onTap: () => _onShuffle(ref, recentSongs),
              ),
              itemCount: recentSongs.length,
              itemBuilder: (context, index) {
                final song = recentSongs[index];
                return SongCard(
                  song: song,
                  isPlaying: song.id == currentSongId,
                  onTap: () =>
                      ref.read(playbackProvider.notifier).playSong(song),
                );
              },
            ),
          ],
          if (recentAlbums.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            HorizontalSection(
              title: 'Recent Albums',
              subtitle: 'Albums you have been listening to',
              icon: Icons.album_rounded,
              accent: AppColors.success,
              height: _squareRowHeight,
              itemCount: recentAlbums.length,
              itemBuilder: (context, index) {
                final item = recentAlbums[index];
                return RecentItemCard(
                  item: item,
                  onTap: () => _onItemTap(context, ref, item),
                );
              },
            ),
          ],
          if (recentArtists.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            HorizontalSection(
              title: 'Recent Artists',
              subtitle: 'Artists on your radar',
              icon: Icons.mic_external_on_rounded,
              accent: AppColors.secondary,
              height: _squareRowHeight,
              itemCount: recentArtists.length,
              itemBuilder: (context, index) {
                final item = recentArtists[index];
                return RecentItemCard(
                  item: item,
                  onTap: () => _onItemTap(context, ref, item),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// User's own + joined rooms, live ones first, deduped by id.
  List<Room> _myLiveRooms(WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) return const [];

    final seen = <String>{};
    final rooms = <Room>[];
    for (final room in [...?user.myRooms, ...?user.joinedRooms]) {
      if (seen.add(room.id)) rooms.add(room);
    }
    rooms.sort((a, b) {
      if (a.playing != b.playing) return a.playing ? -1 : 1;
      return 0;
    });
    return rooms;
  }

  List<RecentItem> _itemsOfType(
    List<RecentItem> items,
    RecentItemType type,
  ) {
    final seen = <String>{};
    final result = <RecentItem>[];
    for (final item in items) {
      if (item.type == type && seen.add(item.id)) {
        result.add(item);
      }
    }
    return result;
  }

  void _onItemTap(BuildContext context, WidgetRef ref, RecentItem item) {
    ref.read(playbackProvider.notifier).setCurrentlyPlaying(
      CurrentlyPlaying(
        sourceId: item.id,
        sourceName: item.name,
        type: PlayingSourceType.values.byName(item.type.name),
        thumbnail: item.thumbnail,
      ),
    );
    context.push(item.routePath);
  }

  void _onShuffle(WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return;
    final rng = Random();
    final song = songs[rng.nextInt(songs.length)];
    ref.read(playbackProvider.notifier).playSong(song);
  }
}

class _ShuffleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShuffleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.cardAlt.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.hairlineDark),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle_rounded, size: 15, color: AppColors.text),
            SizedBox(width: 6),
            Text(
              'Shuffle',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingRoomsSection extends ConsumerWidget {
  final double rowHeight;
  const _TrendingRoomsSection({required this.rowHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(trendingRoomsProvider);

    return rooms.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Trending Rooms',
            subtitle: 'Live sessions happening now',
            icon: Icons.local_fire_department_rounded,
            accent: AppColors.warn,
          ),
          const SizedBox(height: AppSpacing.s3),
          LoadingRow(itemWidth: 236, itemHeight: rowHeight),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rooms) {
        if (rooms.isEmpty) return const SizedBox.shrink();
        return HorizontalSection(
          title: 'Trending Rooms',
          subtitle: 'Live sessions happening now',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.warn,
          height: rowHeight,
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return RoomCard(
              room: room,
              onTap: () => context.push('/room/${room.id}'),
            );
          },
        );
      },
    );
  }
}

class _TrendingPlaylistsSection extends ConsumerWidget {
  final double rowHeight;
  const _TrendingPlaylistsSection({required this.rowHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(trendingPlaylistsProvider);

    return playlists.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Trending Playlists',
            subtitle: 'Curated by the community',
            icon: Icons.queue_music_rounded,
            accent: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.s3),
          LoadingRow(itemWidth: 150, itemHeight: rowHeight),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (playlists) {
        if (playlists.isEmpty) return const SizedBox.shrink();
        return HorizontalSection(
          title: 'Trending Playlists',
          subtitle: 'Curated by the community',
          icon: Icons.queue_music_rounded,
          accent: AppColors.secondary,
          height: rowHeight,
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return PlaylistCard(
              playlist: playlist,
              onTap: () => context.push('/playlist/${playlist.id}'),
            );
          },
        );
      },
    );
  }
}
