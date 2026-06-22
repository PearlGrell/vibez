import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/artist.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/search_provider.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/repositories/search_repository.dart';
import 'package:vibez/presentation/common/song_options_bottom_sheet.dart';
import 'package:vibez/presentation/discover/widgets/album_tile.dart';
import 'package:vibez/presentation/discover/widgets/artist_tile.dart';
import 'package:vibez/presentation/discover/widgets/filter_tab.dart';
import 'package:vibez/presentation/discover/widgets/search_skeleton.dart';
import 'package:vibez/presentation/discover/widgets/song_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterChips(context, state),
        const SizedBox(height: AppSpacing.s4),
        Expanded(child: _buildContent(context, state)),
      ],
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips(BuildContext context, SearchState state) {
    final tabs = <FilterTab>[
      FilterTab(filter: SearchFilter.all, label: 'All'),
      FilterTab(filter: SearchFilter.song, label: 'Songs'),
      FilterTab(filter: SearchFilter.artist, label: 'Artists'),
      FilterTab(filter: SearchFilter.album, label: 'Albums'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        spacing: 8,
        children: tabs.map((tab) {
          final isSelected = state.filter == tab.filter;
          return GestureDetector(
            onTap: () {
              ref.read(searchProvider.notifier).setFilter(tab.filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.hairlineDark,
                  width: 1,
                ),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text2,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Content Router ───────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, SearchState state) {
    if (state.isLoading) return const SearchSkeleton();

    if (state.errorMessage != null) {
      return _buildError(context, state.errorMessage!);
    }

    final songs = state.result?.songs ?? const [];
    final artists = state.result?.artists ?? const [];
    final albums = state.result?.albums ?? const [];

    switch (state.filter) {
      case SearchFilter.all:
        return _buildAllView(context, songs, artists, albums, state);
      case SearchFilter.song:
        return _buildFilteredList(
          context,
          state,
          items: songs,
          emptyLabel: 'No songs found',
          builder: (song) => SongTile(
            song: song,
            onTap: () => _playSong(song),
            onLike: () => ref.read(userProvider.notifier).likeSong(song.id),
            onMore: () => _showMoreSheet(context, song),
            isLiked:
                ref
                    .watch(userProvider)
                    ?.likedSongs
                    ?.any((s) => s.id == song.id) ??
                false,
            isPlaying: ref.watch(playbackProvider).currentSong?.id == song.id,
          ),
        );
      case SearchFilter.artist:
        return _buildFilteredList(
          context,
          state,
          items: artists,
          emptyLabel: 'No artists found',
          builder: (artist) => ArtistTile(
            artist: artist,
            onTap: () => context.push('/artist/${artist.id}'),
          ),
        );
      case SearchFilter.album:
        return _buildFilteredList(
          context,
          state,
          items: albums,
          emptyLabel: 'No albums found',
          builder: (album) => AlbumTile(
            album: album,
            onTap: () => context.push('/album/${album.id}'),
          ),
        );
    }
  }

  // ── "All" Mixed View ─────────────────────────────────────────────────────

  Widget _buildAllView(
    BuildContext context,
    List<SearchSong> songs,
    List<SearchArtist> artists,
    List<SearchAlbum> albums,
    SearchState state,
  ) {
    if (songs.isEmpty && artists.isEmpty && albums.isEmpty) {
      return _buildEmpty('No results found');
    }

    final mixed = _interleave(songs, artists, albums);
    final currentSongId = ref.watch(playbackProvider).currentSong?.id;
    final userState = ref.watch(userProvider);

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: mixed.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= mixed.length) {
          return _buildLoadingMore();
        }

        final item = mixed[index];
        if (item is SearchSong) {
          final isLiked =
              userState?.likedSongs?.any((s) => s.id == item.id) ?? false;
          return SongTile(
            song: item,
            onTap: () => _playSong(item),
            onLike: () => ref.read(userProvider.notifier).likeSong(item.id),
            onMore: () => _showMoreSheet(context, item),
            isLiked: isLiked,
            isPlaying: currentSongId == item.id,
          );
        } else if (item is SearchArtist) {
          return ArtistTile(
            artist: item,
            onTap: () => context.push('/artist/${item.id}'),
          );
        } else if (item is SearchAlbum) {
          return AlbumTile(
            album: item,
            onTap: () => context.push('/album/${item.id}'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  List<Object> _interleave(
    List<SearchSong> songs,
    List<SearchArtist> artists,
    List<SearchAlbum> albums,
  ) {
    final items = <Object>[];
    int si = 0, ai = 0, bi = 0;

    while (si < songs.length || ai < artists.length || bi < albums.length) {
      for (int i = 0; i < 3 && si < songs.length; i++, si++) {
        items.add(songs[si]);
      }
      if (ai < artists.length) {
        items.add(artists[ai++]);
      }
      for (int i = 0; i < 2 && si < songs.length; i++, si++) {
        items.add(songs[si]);
      }
      if (bi < albums.length) {
        items.add(albums[bi++]);
      }
    }

    return items;
  }

  // ── Generic Filtered List ────────────────────────────────────────────────

  Widget _buildFilteredList<T>(
    BuildContext context,
    SearchState state, {
    required List<T> items,
    required String emptyLabel,
    required Widget Function(T) builder,
  }) {
    if (items.isEmpty) return _buildEmpty(emptyLabel);

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) return _buildLoadingMore();
        return builder(items[index]);
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _playSong(SearchSong song) {
    ref
        .read(playbackProvider.notifier)
        .playSong(
          Song(
            id: song.id,
            title: song.title,
            duration: song.duration,
            thumbnail: song.thumbnail,
            artists: [Artist(id: '', name: song.artists)],
          ),
        );
    ref
        .read(playbackProvider.notifier)
        .setCurrentlyPlaying(
          CurrentlyPlaying(
            sourceId: song.id,
            sourceName: song.title,
            type: PlayingSourceType.song,
            thumbnail: song.thumbnail,
          ),
        );
  }

  void _showMoreSheet(BuildContext context, SearchSong song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(song: song),
    );
  }

  Widget _buildLoadingMore() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.text3),
          const SizedBox(height: AppSpacing.s3),
          Text(message, style: AppTypography.small),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 44,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s5),
            FilledButton.icon(
              onPressed: () {
                ref.read(searchProvider.notifier).executeSearch();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.text,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.pillBorderRadius,
                  side: const BorderSide(color: AppColors.hairlineDark),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
