import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/presentation/player/widgets/now_playing_tile.dart';
import 'package:vibez/presentation/player/widgets/queue_song_tile.dart';
import 'package:vibez/presentation/player/widgets/related_song_tile.dart';
import 'package:vibez/presentation/player/widgets/show_more_button.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  static const int _pageSize = 10;
  int _visibleQueueCount = _pageSize;
  int _visibleRelatedCount = _pageSize;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final currentSong = playback.currentSong;
    final queue = playback.queue;
    final autoplayQueue = playback.autoplayQueue;
    final source = playback.currentlyPlaying;

    final filteredRelated = autoplayQueue.where((song) {
      final isCurrent = currentSong?.id == song.id;
      final isInQueue = queue.any((s) => s.id == song.id);
      return !isCurrent && !isInQueue;
    }).toList();

    final hasSource = source != null && source.type != PlayingSourceType.song;

    return Container(
      color: AppColors.background,
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(context, source, playback),
                const Divider(color: AppColors.hairlineLight, height: 1),
                Expanded(
                  child: currentSong == null
                      ? _buildEmpty(context)
                      : _buildBody(
                          context,
                          scrollController,
                          currentSong,
                          queue,
                          filteredRelated,
                          playback,
                          hasSource,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.text3.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CurrentlyPlaying? source,
    PlaybackState playback,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s1,
        AppSpacing.s4,
        AppSpacing.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Queue",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (source != null) ...[
                      Icon(
                        _sourceIcon(source.type),
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Playing from ${source.sourceName}",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.text3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      Text(
                        "Solo listening",
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.text3),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Shuffle',
            icon: Icon(
              Icons.shuffle_rounded,
              color: playback.shuffle ? AppColors.primary : AppColors.text2,
              size: 22,
            ),
            onPressed: () {
              ref.read(playbackProvider.notifier).toggleShuffle();
            },
          ),
          IconButton(
            tooltip: playback.repeatMode == RepeatMode.one
                ? 'Repeat One'
                : playback.repeatMode == RepeatMode.all
                ? 'Repeat All'
                : 'Repeat Off',
            icon: Icon(
              playback.repeatMode == RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: playback.repeatMode != RepeatMode.none
                  ? AppColors.primary
                  : AppColors.text2,
              size: 22,
            ),
            onPressed: () {
              ref.read(playbackProvider.notifier).toggleRepeatMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.s3,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 64,
            color: AppColors.hairlineDark,
          ),
          Text(
            "Your queue is empty",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.text3),
          ),
          Text(
            "Play something to get started",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScrollController scrollController,
    Song currentSong,
    List<Song> queue,
    List<Song> filteredRelated,
    PlaybackState playback,
    bool hasSource,
  ) {
    final paginatedQueue = queue.take(_visibleQueueCount).toList();
    final hasMoreQueue = queue.length > _visibleQueueCount;
    final paginatedRelated = filteredRelated
        .take(_visibleRelatedCount)
        .toList();
    final hasMoreRelated = filteredRelated.length > _visibleRelatedCount;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s3,
            AppSpacing.s5,
            AppSpacing.s1,
          ),
          child: Text(
            "NOW PLAYING",
            style: Theme.of(context).textTheme.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.text3,
            ),
          ),
        ),
        NowPlayingTile(
          song: currentSong,
          isPlaying: playback.playing,
          onTap: () {
            ref.read(playbackProvider.notifier).togglePlay();
          },
        ),

        if (paginatedQueue.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PLAYING NEXT${hasSource ? '' : ''} · ${queue.length}",
                  style: Theme.of(context).textTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text3,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(playbackProvider.notifier).clearQueue();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: AppColors.text3,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "Clear",
                        style: Theme.of(context).textTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...paginatedQueue.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return QueueSongTile(
              key: ValueKey('queue_${song.id}_$index'),
              song: song,
              index: index,
              formatDuration: _formatDuration,
              onTap: () {
                ref.read(playbackProvider.notifier).playSongFromQueue(song);
              },
              onRemove: () {
                ref.read(playbackProvider.notifier).removeFromQueueAt(index);
              },
            );
          }),
          if (hasMoreQueue)
            ShowMoreButton(
              remaining: queue.length - _visibleQueueCount,
              onTap: () {
                setState(() {
                  _visibleQueueCount += _pageSize;
                });
              },
            ),
        ],

        if (paginatedRelated.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s5,
              AppSpacing.s1,
            ),
            child: Text(
              "RECOMMENDED",
              style: Theme.of(context).textTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.text3,
              ),
            ),
          ),
          ...paginatedRelated.asMap().entries.map((entry) {
            final song = entry.value;
            return RelatedSongTile(
              key: ValueKey('related_${song.id}'),
              song: song,
              formatDuration: _formatDuration,
              onTap: () {
                ref.read(playbackProvider.notifier).addToQueueNext(song);
                ref.read(playbackProvider.notifier).playNext();
              },
              onAddToQueue: () {
                ref.read(playbackProvider.notifier).addToQueue(song);
              },
            );
          }),
          if (hasMoreRelated)
            ShowMoreButton(
              remaining: filteredRelated.length - _visibleRelatedCount,
              onTap: () {
                setState(() {
                  _visibleRelatedCount += _pageSize;
                });
              },
            ),
        ],

        const SizedBox(height: AppSpacing.s9),
      ],
    );
  }

  IconData _sourceIcon(PlayingSourceType type) {
    switch (type) {
      case PlayingSourceType.album:
        return Icons.album_rounded;
      case PlayingSourceType.playlist:
        return Icons.queue_music_rounded;
      case PlayingSourceType.artist:
        return Icons.person_rounded;
      case PlayingSourceType.song:
        return Icons.music_note_rounded;
    }
  }
}
