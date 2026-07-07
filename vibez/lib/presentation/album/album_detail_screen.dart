import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/album.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/repositories/album_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/song_options_bottom_sheet.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/core/utils/share_util.dart';
import 'package:vibez/presentation/common/details_skeleton.dart';
import 'package:vibez/presentation/common/search_song_helper.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  Album? _album;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlbum();
  }

  Future<void> _fetchAlbum() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final album = await AlbumRepository.instance.getAlbum(widget.albumId);
      if (mounted) {
        setState(() {
          _album = album;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load album details.";
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(
        song: SearchSongHelper.fromSong(song, albumTitle: _album?.title ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    if (_isLoading) {
      return const DetailsSkeleton(isArtist: false);
    }

    if (_errorMessage != null || _album == null) {
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
            _errorMessage ?? "Album details not found.",
            style: const TextStyle(color: AppColors.text2, fontSize: 16),
          ),
        ),
      );
    }

    final album = _album!;
    final isLiked =
        userState?.likedAlbums?.any((a) => a.id == album.id) ?? false;
    final songs = (album.songs ?? []).map((s) {
      if ((s.thumbnail == null || s.thumbnail!.isEmpty) &&
          album.thumbnail != null &&
          album.thumbnail!.isNotEmpty) {
        return s.copyWith(thumbnail: album.thumbnail);
      }
      return s;
    }).toList();
    final artistsStr = album.artists?.map((a) => a.name).join(', ') ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchAlbum,
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
                  AppIconButton(
                    icon: Icons.ios_share_rounded,
                    iconSize: 18,
                    onTap: () async {
                      ShareUtil(
                        shareMode: .album,
                        id: album.id,
                        title: album.title,
                        url: album.thumbnail,
                      ).share().then((value) {
                        if (!value) {
                          AppSnackbar.show(
                            message: "Failed to share",
                            type: AppSnackType.error,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      AlbumArtCover(
                        seed: album.title,
                        size: 180,
                        radius: AppRadius.sm,
                        child:
                            album.thumbnail != null &&
                                album.thumbnail!.isNotEmpty
                            ? Image.network(
                                album.thumbnail!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              )
                            : null,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        album.title,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 24,
                            width: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                album.artists?.firstOrNull?.thumbnail != null &&
                                    album.artists!.first.thumbnail!.isNotEmpty
                                ? Image.network(
                                    album.artists!.first.thumbnail!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Text(
                                            artistsStr.isNotEmpty
                                                ? artistsStr[0].toUpperCase()
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
                                      artistsStr.isNotEmpty
                                          ? artistsStr[0].toUpperCase()
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
                          Flexible(
                            child: GestureDetector(
                              onTap: () {
                                final artist = album.artists?.firstOrNull;
                                if (artist != null && artist.id.isNotEmpty) {
                                  context.push('/artist/${artist.id}');
                                }
                              },
                              child: Text(
                                artistsStr,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.text2,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        "${album.type ?? 'Album'}  •  ${album.year ?? ''}  •  ${songs.length} songs  •  ${_formatTotalDuration(songs)}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text3,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked
                                  ? AppColors.danger
                                  : AppColors.text2,
                              size: 26,
                            ),
                            onPressed: () {
                              if (isLiked) {
                                ref
                                    .read(userProvider.notifier)
                                    .unlikeAlbum(album.id);
                              } else {
                                ref
                                    .read(userProvider.notifier)
                                    .likeAlbum(album);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.shuffle_rounded,
                              color: AppColors.text2,
                              size: 26,
                            ),
                            onPressed: () {
                              ref
                                  .read(playbackProvider.notifier)
                                  .toggleShuffle();
                              AppSnackbar.show(
                                message: "Shuffle toggled",
                                type: AppSnackType.success,
                              );
                            },
                          ),
                          const Spacer(),
                          if (songs.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(playbackProvider.notifier)
                                    .playSongsFromList(songs, 0);
                                ref
                                    .read(playbackProvider.notifier)
                                    .setCurrentlyPlaying(CurrentlyPlaying(
                                      type: PlayingSourceType.album,
                                      sourceId: album.id,
                                      sourceName: album.title,
                                      thumbnail: album.thumbnail,
                                    ));
                              },
                              child: Container(
                                height: 56,
                                width: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899),
                                    ],
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
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "No tracks in this album.",
                          style: TextStyle(
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
                              userState?.likedSongs?.any(
                                (s) => s.id == song.id,
                              ) ??
                              false;
                          final songArtistsStr =
                              song.artists?.map((a) => a.name).join(', ') ??
                              artistsStr;

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
                                    .setCurrentlyPlaying(CurrentlyPlaying(
                                      type: PlayingSourceType.album,
                                      sourceId: album.id,
                                      sourceName: album.title,
                                      thumbnail: album.thumbnail,
                                    ));
                              },
                              borderRadius: AppRadius.smBorderRadius,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: AppColors.text3,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
                                            '$songArtistsStr • ${_formatDuration(song.duration)}',
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
