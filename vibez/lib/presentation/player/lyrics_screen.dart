import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/provider/playback_provider.dart' hide LoadState;
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/data/services/player_audio_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/presentation/player/widgets/ghost_loading_lyrics.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  int _activeIndex = -1;
  StreamSubscription<Duration>? _positionSub;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queue = ref.read(playbackProvider);
      final isDownloadMode = queue.currentlyPlaying?.sourceId == 'downloads';
      if (!isDownloadMode) {
        ref.read(songCacheProvider.notifier).loadLyrics();
      }
    });
    _positionSub = PlayerAudioService.vibezHandler.positionStream.listen(
      _onPosition,
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _onPosition(Duration position) {
    final cache = ref.read(songCacheProvider);
    final lyrics = cache.currentLyrics;
    if (lyrics == null || lyrics.lyrics.isEmpty) return;

    final newIndex = lyrics.lyrics.indexWhere((block) {
      return position >= Duration(milliseconds: block.startTime) &&
          position < Duration(milliseconds: block.endTime);
    });

    if (newIndex != -1 && newIndex != _activeIndex) {
      setState(() => _activeIndex = newIndex);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.3,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackProvider);
    final cache = ref.watch(songCacheProvider);
    final currentSong = queue.currentSong;
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: kToolbarHeight - AppSpacing.s1),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppIconButton(
            icon: Icons.keyboard_arrow_down_outlined,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          title: queue.currentlyPlaying != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s1 / 2,
                  children: [
                    Row(
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
                )
              : Text(
                  "Lyrics",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2,
                  ),
                ),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.hairlineDark),
                ),
                borderRadius: AppRadius.pillBorderRadius,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s1,
              ),
              child: Row(
                spacing: AppSpacing.s2,
                children: [
                  Icon(
                    Icons.mic_none_outlined,
                    size: 14,
                    color: AppColors.text2,
                  ),
                  Text(
                    "Lyrics",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _buildLyricsBody(context, cache),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.hairlineDark, width: 0.75),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s4,
            ),
            child: Row(
              spacing: AppSpacing.s3,
              children: [
                AlbumArtCover(
                  seed: currentSong?.title ?? 'Unknown',
                  size: 48,
                  radius: AppRadius.sm,
                  child:
                      currentSong?.thumbnail != null &&
                          currentSong!.thumbnail!.isNotEmpty
                      ? Image.network(
                          currentSong.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        )
                      : null,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong?.title ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      StreamBuilder<Duration>(
                        stream: PlayerAudioService.vibezHandler.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final totalDuration = Duration(
                            seconds: currentSong?.duration ?? 0,
                          );
                          return Text(
                            "${_formatDuration(position)} / ${_formatDuration(totalDuration)}",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.text2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillBorderRadius,
                    boxShadow: AppShadows.shGlowMd,
                  ),
                  child: IconButton.filled(
                    icon: Icon(queue.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (queue.playing) {
                        ref.read(playbackProvider.notifier).pause();
                      } else {
                        ref.read(playbackProvider.notifier).play();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsBody(BuildContext context, SongCacheState cache) {
    switch (cache.lyricsLoadState) {
      case LoadState.loading:
        return const GhostLoadingLyrics();

      case LoadState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.s3,
            children: [
              Icon(Icons.music_off, size: 64, color: AppColors.hairlineDark),
              Text(
                "Couldn't load lyrics for this track",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
              ),
            ],
          ),
        );

      case LoadState.success:
      case LoadState.idle:
        final lyrics = cache.currentLyrics;
        if (lyrics == null || lyrics.lyrics.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.s3,
              children: [
                Icon(Icons.music_off, size: 64, color: AppColors.hairlineDark),
                Text(
                  "Looks like we don't have lyrics for this one",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
                ),
              ],
            ),
          );
        }

        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ).copyWith(bottom: MediaQuery.of(context).size.height / 2),
          itemCount: lyrics.lyrics.length,
          itemBuilder: (context, index) {
            final block = lyrics.lyrics[index];
            final active = index == _activeIndex;

            return Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  height: 1.5,
                  fontSize: 24,
                  color: active ? AppColors.text : AppColors.text3,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    PlayerAudioService.handler.seek(
                      Duration(milliseconds: block.startTime),
                    );
                  },
                  child: Text(block.text),
                ),
              ),
            );
          },
        );
    }
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
