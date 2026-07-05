import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/playlist.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/repositories/playlist_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/song_options_bottom_sheet.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/presentation/common/details_skeleton.dart';
import 'package:vibez/presentation/common/search_song_helper.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  Playlist? _playlist;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlaylist();
  }

  Future<void> _fetchPlaylist() async {
    // Virtual playlists ('liked-songs', 'history') have no server record —
    // they render from local/provider state, so there is nothing to fetch.
    if (widget.playlistId == 'liked-songs' || widget.playlistId == 'history') {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final playlist = await PlaylistRepository.instance.getPlaylist(
        widget.playlistId,
      );
      if (mounted) {
        setState(() {
          _playlist = playlist;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load playlist details.";
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatTotalDuration(List<Song> songs) {
    final totalSeconds = songs.fold(0, (sum, song) => sum + song.duration);
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hr $remainingMinutes min';
    }
  }

  void _showMoreSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(
        song: SearchSongHelper.fromSong(song),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isLikedSongs = widget.playlistId == 'liked-songs';
    final isHistory = widget.playlistId == 'history';
    final isVirtual = isLikedSongs || isHistory;
    final playback = ref.watch(playbackProvider);

    final String playlistName = isHistory
        ? "History"
        : isLikedSongs
        ? "Liked Songs"
        : (_playlist?.name ?? "");
    final String description = isHistory
        ? "The last songs you played."
        : isLikedSongs
        ? "Everything you've hearted."
        : (_playlist?.description ?? _playlist?.tags.join(', ') ?? "");
    final List<Song> songs = isHistory
        ? playback.recentlyPlayed
        : isLikedSongs
        ? (userState?.likedSongs ?? [])
        : (_playlist?.songs ?? []);
    final bool isOwnerPlaylist = !isVirtual && _playlist?.createdById == userState?.id;
    final String creatorName = isVirtual || isOwnerPlaylist
        ? "you"
        : (_playlist?.createdBy?.name ?? "Unknown");

    final String? profileUrl = isVirtual || isOwnerPlaylist
        ? userState?.profileUrl
        : _playlist?.createdBy?.profileUrl;
    final String creatorNameToShow = creatorName;
    final profileColor =
        profileUrl != null && profileUrl.startsWith('default://')
        ? Color(
            int.parse(
              'FF${profileUrl.replaceFirst('default://', '')}',
              radix: 16,
            ),
          )
        : const Color(0xFF8B5CF6);

    if (_isLoading) {
      return const DetailsSkeleton(isArtist: false);
    }

    if (_errorMessage != null && !isVirtual) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppIconButton(
            icon: Icons.chevron_left,
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamed(context, '/');
              }
            },
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.text2, fontSize: 16),
          ),
        ),
      );
    }

    final isOwner = !isVirtual && _playlist?.createdById == userState?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isOwner
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () async {
                  await context.push(
                    '/search-add-song',
                    extra: {
                      'playlistId': widget.playlistId,
                      'playlistName': playlistName,
                    },
                  );
                  PlaylistRepository.instance.invalidateCache(widget.playlistId);
                  _fetchPlaylist();
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchPlaylist,
        color: AppColors.primary,
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            leading: AppIconButton(
              icon: Icons.chevron_left,
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamed(context, '/');
                }
              },
            ),
            actions: [
              if (!isVirtual && _playlist?.createdById == userState?.id)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await context.push('/playlist-add', extra: _playlist);
                        PlaylistRepository.instance.invalidateCache(
                          widget.playlistId,
                        );
                        _fetchPlaylist();
                      },
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  isVirtual
                      ? Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isHistory
                                  ? const [Color(0xFF6366F1), Color(0xFF06B6D4)]
                                  : const [
                                      Color(0xFFEC4899),
                                      Color(0xFF8B5CF6),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppRadius.smBorderRadius,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isHistory ? Icons.history_rounded : Icons.favorite,
                            size: 80,
                            color: Colors.white,
                          ),
                        )
                      : AlbumArtCover(
                          seed: playlistName,
                          size: 180,
                          radius: AppRadius.sm,
                          child:
                              _playlist?.thumbnail != null &&
                                  _playlist!.thumbnail!.isNotEmpty
                              ? Image.network(
                                  _playlist!.thumbnail!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                )
                              : null,
                        ),
                  const SizedBox(height: 24),

                  Text(
                    playlistName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: profileColor,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            (profileUrl != null &&
                                profileUrl.isNotEmpty &&
                                !profileUrl.startsWith('default://'))
                            ? Image.network(
                                profileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        creatorNameToShow.isNotEmpty
                                            ? creatorNameToShow[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              )
                            : Center(
                                child: Text(
                                  creatorNameToShow.isNotEmpty
                                      ? creatorNameToShow[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (!isVirtual && !isOwnerPlaylist && _playlist?.createdBy != null) {
                            context.push('/user/${_playlist!.createdBy!.id}');
                          }
                        },
                        child: Text(
                          creatorNameToShow,
                          style: const TextStyle(
                            color: AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!isVirtual) ...[
                        const SizedBox(width: 6),
                        Icon(
                          _playlist?.private == true
                              ? Icons.lock_rounded
                              : Icons.public_rounded,
                          size: 14,
                          color: _playlist?.private == true
                              ? AppColors.text3
                              : AppColors.success,
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        "•  ${songs.length} songs  •  ${_formatTotalDuration(songs)}",
                        style: const TextStyle(
                          color: AppColors.text3,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shuffle_rounded,
                          color: AppColors.text2,
                          size: 26,
                        ),
                        onPressed: () {
                          ref.read(playbackProvider.notifier).toggleShuffle();
                          AppSnackbar.show(
                            message: "Shuffle toggled",
                            type: AppSnackType.success,
                          );
                        },
                      ),
                      if (!isVirtual && !isOwner && _playlist != null)
                        Builder(builder: (context) {
                          final isLiked = userState?.likedPlaylists?.any(
                                (p) => p.id == _playlist!.id,
                              ) ?? false;
                          return IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? AppColors.danger : AppColors.text2,
                              size: 26,
                            ),
                            onPressed: () {
                              if (isLiked) {
                                ref.read(userProvider.notifier).unlikePlaylist(_playlist!.id);
                              } else {
                                ref.read(userProvider.notifier).likePlaylist(_playlist!);
                              }
                            },
                          );
                        }),
                      const Spacer(),
                      if (songs.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(playbackProvider.notifier)
                                .playSongsFromList(songs, 0);
                            ref
                                .read(playbackProvider.notifier)
                                .setCurrentlyPlaying(
                                  CurrentlyPlaying(
                                    type: PlayingSourceType.playlist,
                                    sourceId: widget.playlistId,
                                    sourceName: playlistName,
                                    thumbnail: _playlist?.thumbnail,
                                  ),
                                );
                          },
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          songs.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      isHistory
                          ? "Nothing played yet. Your history will show up here."
                          : isLikedSongs
                          ? "No liked songs yet."
                          : "No songs in this playlist yet.",
                      style: const TextStyle(
                        color: AppColors.text3,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = songs[index];
                      final isSongLiked =
                          userState?.likedSongs?.any((s) => s.id == song.id) ??
                          false;
                      final artistsStr =
                          song.artists?.map((a) => a.name).join(', ') ?? '';

                      return Container(
                        key: ValueKey(song.id),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(playbackProvider.notifier)
                                .playSongsFromList(songs, index);
                            ref
                                .read(playbackProvider.notifier)
                                .setCurrentlyPlaying(
                                  CurrentlyPlaying(
                                    type: PlayingSourceType.playlist,
                                    sourceId: widget.playlistId,
                                    sourceName: playlistName,
                                    thumbnail: _playlist?.thumbnail,
                                  ),
                                );
                          },
                          borderRadius: AppRadius.smBorderRadius,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                AlbumArtCover(
                                  seed: song.title,
                                  size: 50,
                                  radius: AppRadius.sm,
                                  child:
                                      song.thumbnail != null &&
                                          song.thumbnail!.isNotEmpty
                                      ? Image.network(
                                          song.thumbnail!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$artistsStr • ${_formatDuration(song.duration)}',
                                        style: const TextStyle(
                                          color: AppColors.text2,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isSongLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isSongLiked
                                        ? AppColors.danger
                                        : AppColors.text3,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(userProvider.notifier)
                                        .likeSong(song.id);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: AppColors.text3,
                                  ),
                                  onPressed: () =>
                                      _showMoreSheet(context, song),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: songs.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      ),
    );
  }
}
