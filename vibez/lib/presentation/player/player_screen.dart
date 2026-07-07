import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/downloads_provider.dart';
import 'package:vibez/data/provider/song_cache_provider.dart' hide LoadState;
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/player/widgets/custom_track_shape.dart';
import 'package:vibez/data/services/player_audio_service.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/album_art_glow.dart';
import 'package:vibez/core/utils/thumbnail.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/presentation/player/credits_screen.dart';
import 'package:vibez/presentation/player/lyrics_screen.dart';
import 'package:vibez/presentation/player/queue_screen.dart';
import 'package:vibez/presentation/player/widgets/sleep_timer_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  static const int _kCenterPage = 1000;
  late final PageController _pageController;
  bool _isAnimating = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _timestampMode = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  IconData _sourceIcon(PlayingSourceType? type) {
    switch (type) {
      case PlayingSourceType.album:
        return Icons.album_rounded;
      case PlayingSourceType.playlist:
        return Icons.queue_music_rounded;
      case PlayingSourceType.artist:
        return Icons.person_rounded;
      case PlayingSourceType.song:
      case null:
        return Icons.music_note_rounded;
    }
  }

  String _sourceLabel(CurrentlyPlaying? source) {
    if (source == null) return 'NOW PLAYING';
    switch (source.type) {
      case PlayingSourceType.album:
        return 'PLAYING FROM ALBUM';
      case PlayingSourceType.playlist:
        return 'PLAYING FROM PLAYLIST';
      case PlayingSourceType.artist:
        return 'PLAYING FROM ARTIST';
      case PlayingSourceType.song:
        return 'NOW PLAYING';
    }
  }

  Widget _buildDownloadButton(Song song) {
    final downloads = ref.watch(downloadsProvider);
    final isDownloaded = downloads.isDownloaded(song.id);
    final isDownloading = downloads.isDownloading(song.id);

    if (isDownloading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final notifier = ref.read(downloadsProvider.notifier);
        if (isDownloaded) {
          await notifier.removeDownload(song.id);
          AppSnackbar.show(
            message: 'Removed download',
            type: AppSnackType.success,
          );
        } else {
          final ok = await notifier.downloadSong(song);
          AppSnackbar.show(
            message: ok ? 'Downloaded for offline' : 'Download failed',
            type: ok ? AppSnackType.success : AppSnackType.error,
          );
        }
      },
      child: Icon(
        isDownloaded ? Icons.download_done_rounded : Icons.download_outlined,
        color: isDownloaded ? AppColors.primary : AppColors.text2,
        size: 21,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kCenterPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (_isAnimating) return;
    if (page > _kCenterPage) {
      ref.read(playbackProvider.notifier).playNext();
    } else if (page < _kCenterPage) {
      ref.read(playbackProvider.notifier).playPrevious();
    }
  }

  void _showPlaylistSelector(BuildContext context, String songId) {
    final userState = ref.read(userProvider);
    final playlists = userState?.playlists ?? [];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: AppColors.hairlineLight, width: 1),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add to Playlist",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt,
                      borderRadius: AppRadius.smBorderRadius,
                      border: Border.all(color: AppColors.hairlineLight),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    "Create new playlist",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/playlist-add');
                  },
                ),
                if (playlists.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.hairlineLight, height: 1),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: AlbumArtCover(
                            seed: playlist.name,
                            size: 40,
                            radius: AppRadius.xs,
                            child:
                                playlist.thumbnail != null &&
                                    playlist.thumbnail!.isNotEmpty
                                ? Image.network(
                                    playlist.thumbnail!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "${playlist.songs?.length ?? 0} songs",
                            style: const TextStyle(color: AppColors.text3),
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final success = await ref
                                .read(userProvider.notifier)
                                .addSongToPlaylist(
                                  playlistId: playlist.id,
                                  songId: songId,
                                );
                            if (success) {
                              AppSnackbar.show(
                                message: "Added to '${playlist.name}'",
                                type: AppSnackType.success,
                              );
                            } else {
                              AppSnackbar.show(
                                message: "Failed to add song.",
                                type: AppSnackType.error,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackProvider);

    ref.listen<PlaybackState>(playbackProvider, (prev, next) {
      if (prev?.currentSong?.id != next.currentSong?.id) {
        ref
            .read(songCacheProvider.notifier)
            .onSongChanged(next.currentSong?.id);

        if (_pageController.hasClients) {
          _isAnimating = true;
          _pageController
              .animateToPage(
                _kCenterPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              )
              .then((_) => _isAnimating = false);
        }
      }
    });

    if (queue.currentSong == null) {
      return const Scaffold(body: Center(child: Text("No song playing")));
    }

    final cacheState = ref.read(songCacheProvider);
    if (cacheState.activeSongId != queue.currentSong!.id) {
      Future.microtask(() {
        ref
            .read(songCacheProvider.notifier)
            .onSongChanged(queue.currentSong!.id);
      });
    }

    return Container(
      color: AppColors.background,
      padding: EdgeInsetsGeometry.only(top: kToolbarHeight - AppSpacing.s1),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: AppIconButton(
            icon: Icons.keyboard_arrow_down_outlined,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          title: queue.currentlyPlaying != null
              ? GestureDetector(
                  onTap: () {
                    final source = queue.currentlyPlaying!;
                    Navigator.pop(context);
                    switch (source.type) {
                      case PlayingSourceType.album:
                        context.push('/album/${source.sourceId}');
                      case PlayingSourceType.playlist:
                        context.push('/playlist/${source.sourceId}');
                      case PlayingSourceType.artist:
                        context.push('/artist/${source.sourceId}');
                      case PlayingSourceType.song:
                        break;
                    }
                  },
                  child: Column(
                    spacing: AppSpacing.s1,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: AppSpacing.s1,
                        children: [
                          Icon(
                            _sourceIcon(queue.currentlyPlaying?.type),
                            size: 14,
                            color: AppColors.text3,
                          ),
                          Text(
                            _sourceLabel(queue.currentlyPlaying),
                            style: Theme.of(context).textTheme.mono(
                              fontSize: 11,
                              color: AppColors.text3,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        queue.currentlyPlaying!.sourceName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              : Text(
                  "Now Playing",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2,
                  ),
                ),
          actions: [
            AppIconButton(
              icon: Icons.queue_music_outlined,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isDismissible: true,
                  enableDrag: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.lg),
                        topRight: Radius.circular(AppRadius.lg),
                      ),
                      child: const QueueScreen(),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final screenWidth = MediaQuery.of(context).size.width;

              const estimatedControlsHeight = 360.0;
              final maxArtSize = screenWidth - (AppSpacing.s6 * 2);
              final calculatedArtSize =
                  availableHeight - estimatedControlsHeight;
              final artSize = calculatedArtSize.clamp(180.0, maxArtSize);

              final isShuffle = queue.shuffle;
              final repeatMode = queue.repeatMode;

              final isLiked =
                  ref
                      .watch(userProvider)
                      ?.likedSongs
                      ?.any((s) => s.id == queue.currentSong!.id) ??
                  false;

              IconData repeatIcon;
              Color repeatColor;
              switch (repeatMode) {
                case RepeatMode.none:
                  repeatIcon = Icons.repeat_rounded;
                  repeatColor = AppColors.text3;
                  break;
                case RepeatMode.all:
                  repeatIcon = Icons.repeat_rounded;
                  repeatColor = AppColors.primary;
                  break;
                case RepeatMode.one:
                  repeatIcon = Icons.repeat_one_rounded;
                  repeatColor = AppColors.primary;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    SizedBox(
                      height: artSize,
                      child: PageView.builder(
                        controller: _pageController,

                        clipBehavior: Clip.none,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          Song? getSongForIndex(int idx) {
                            final offset = idx - _kCenterPage;
                            if (offset == 0) {
                              return queue.currentSong;
                            } else if (offset > 0) {
                              final queueIndex = offset - 1;
                              if (queueIndex < queue.queue.length) {
                                return queue.queue[queueIndex];
                              }
                              if ((queueIndex - queue.queue.length) <
                                  queue.autoplayQueue.length) {
                                return queue.autoplayQueue[queueIndex -
                                    queue.queue.length];
                              }
                              return null;
                            } else {
                              final historyIndex = -offset - 1;
                              if (historyIndex < queue.history.length) {
                                return queue.history[historyIndex];
                              }
                              return null;
                            }
                          }

                          final song =
                              getSongForIndex(index) ?? queue.currentSong;

                          final cover =
                              song?.thumbnail != null &&
                                  song!.thumbnail!.isNotEmpty
                              ? hiResThumbnail(song.thumbnail!)
                              : null;
                          return Center(
                            child: AlbumArtGlow(
                              imageUrl: cover,
                              radius: 20,
                              playing: queue.playing,
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: artSize * 1.2,
                                height: artSize * 1.2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 28,
                                      spreadRadius: -4,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: AlbumArtCover(
                                  size: artSize,
                                  radius: 16,
                                  seed: song?.title ?? 'Voyager',
                                  child: cover != null
                                      ? Image.network(
                                          cover,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(flex: 3),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final albumId =
                                      queue.currentSong!.albumId ??
                                      queue.currentSong!.album?.id;
                                  if (albumId != null && albumId.isNotEmpty) {
                                    Navigator.pop(context);
                                    context.push('/album/$albumId');
                                  }
                                },
                                child: Text(
                                  queue.currentSong!.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Builder(
                                builder: (context) {
                                  final artists = queue.currentSong!.artists;
                                  if (artists == null || artists.isEmpty) {
                                    return Text(
                                      'Unknown Artist',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.text2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    );
                                  }
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (
                                          int i = 0;
                                          i < artists.length;
                                          i++
                                        ) ...[
                                          GestureDetector(
                                            onTap: artists[i].id.isNotEmpty
                                                ? () {
                                                    Navigator.pop(context);
                                                    context.push(
                                                      '/artist/${artists[i].id}',
                                                    );
                                                  }
                                                : null,
                                            child: Text(
                                              artists[i].name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: AppColors.text2,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          if (i < artists.length - 1)
                                            Text(
                                              ", ",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: AppColors.text2,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(userProvider.notifier)
                                .likeSong(queue.currentSong!.id);
                          },
                          icon: isLiked
                              ? const Icon(
                                  Icons.favorite,
                                  color: AppColors.danger,
                                  size: 28,
                                )
                              : const Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppColors.text2,
                                  size: 28,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s4),

                    StreamBuilder<Duration>(
                      stream: PlayerAudioService.vibezHandler.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final loadedDuration = PlayerAudioService
                            .handler
                            .mediaItem
                            .value
                            ?.duration;
                        final totalDuration =
                            loadedDuration ??
                            Duration(seconds: queue.currentSong?.duration ?? 0);
                        final totalMs = totalDuration.inMilliseconds;
                        final positionMs = position.inMilliseconds;

                        double progress = 0.0;
                        if (totalMs > 0) {
                          progress = (positionMs / totalMs).clamp(0.0, 1.0);
                        }

                        final playedStr = _formatDuration(position);
                        final remainingDuration = totalDuration - position;
                        final remainingStr =
                            "-${_formatDuration(remainingDuration >= Duration.zero ? remainingDuration : Duration.zero)}";

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.card,
                                thumbColor: Colors.white,
                                trackShape: CustomTrackShape(),
                              ),
                              child: Slider(
                                value: _isDragging ? _dragValue : progress,
                                onChanged: (v) {
                                  setState(() {
                                    _isDragging = true;
                                    _dragValue = v;
                                  });
                                },
                                onChangeEnd: (v) {
                                  final newPosition = Duration(
                                    milliseconds: (v * totalMs).round(),
                                  );
                                  PlayerAudioService.handler.seek(newPosition);
                                  setState(() {
                                    _isDragging = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    playedStr,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.mono(fontSize: 11),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _timestampMode = !_timestampMode;
                                      });
                                    },
                                    child: Text(
                                      _timestampMode
                                          ? remainingStr
                                          : _formatDuration(totalDuration),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.mono(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.s4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.read(playbackProvider.notifier).toggleShuffle();
                          },
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: isShuffle
                                ? AppColors.primary
                                : AppColors.text2,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(playbackProvider.notifier)
                              .playPrevious(seek: true),
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppShadows.shGlowLg,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(99999),
                          ),
                          child: InkWell(
                            onTap: () {
                              ref.read(playbackProvider.notifier).togglePlay();
                            },
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: Center(
                                child:
                                    queue.playbackLoadState == LoadState.loading
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Icon(
                                        queue.playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 38,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: queue.hasNext
                              ? () => ref
                                    .read(playbackProvider.notifier)
                                    .playNext()
                              : null,
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: queue.hasNext
                                ? Colors.white
                                : AppColors.text2.withValues(alpha: 0.3),
                            size: 38,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(playbackProvider.notifier)
                                .toggleRepeatMode();
                          },
                          icon: Icon(repeatIcon, color: repeatColor, size: 24),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s6),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.hairlineLight,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                useRootNavigator: true,
                                isDismissible: true,
                                enableDrag: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(AppRadius.lg),
                                      topRight: Radius.circular(AppRadius.lg),
                                    ),
                                    child: const LyricsScreen(),
                                  );
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.hairlineLight,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mic_none_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Lyrics",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 10),
                            child: Row(
                              spacing: 16,
                              children: [
                                GestureDetector(
                                  onTap: () => showSleepTimerSheet(context),
                                  child: Icon(
                                    queue.sleepTimerActive
                                        ? Icons.bedtime_rounded
                                        : Icons.bedtime_outlined,
                                    color: queue.sleepTimerActive
                                        ? AppColors.primary
                                        : AppColors.text2,
                                    size: 20,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      useRootNavigator: true,
                                      isDismissible: true,
                                      enableDrag: true,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(
                                              AppRadius.lg,
                                            ),
                                            topRight: Radius.circular(
                                              AppRadius.lg,
                                            ),
                                          ),
                                          child: const CreditsScreen(),
                                        );
                                      },
                                    );
                                  },
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: AppColors.text2,
                                    size: 20,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Icon(
                                    Icons.ios_share_rounded,
                                    color: AppColors.text2,
                                    size: 18,
                                  ),
                                ),
                                _buildDownloadButton(queue.currentSong!),
                                GestureDetector(
                                  onTap: () {
                                    _showPlaylistSelector(
                                      context,
                                      queue.currentSong!.id,
                                    );
                                  },
                                  child: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.text2,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
