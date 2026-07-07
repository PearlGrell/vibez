import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/image_cache_size.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/player/player_screen.dart';

class Miniplayer extends ConsumerStatefulWidget {
  const Miniplayer({super.key});

  @override
  ConsumerState<Miniplayer> createState() => _MiniplayerState();
}

class _MiniplayerState extends ConsumerState<Miniplayer> {
  PageController? _controller;
  String? _currentSongId;
  bool? _hasPrevious;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final currentSong = playback.currentSong;

    if (currentSong == null) {
      _controller?.dispose();
      _controller = null;
      _currentSongId = null;
      _hasPrevious = null;
      return const SizedBox.shrink();
    }

    final hasNext = playback.hasNext;
    final hasPrevious = playback.hasPrevious;

    final songTitle = currentSong.title;
    final artistsName =
        currentSong.artists?.map((e) => e.name).join(', ') ?? 'Unknown Artist';

    final previousSong = hasPrevious ? playback.history.first : null;
    final nextSong = hasNext
        ? (playback.queue.isNotEmpty
              ? playback.queue.first
              : (playback.autoplayQueue.isNotEmpty
                    ? playback.autoplayQueue.first
                    : null))
        : null;

    if (_controller == null ||
        _currentSongId != currentSong.id ||
        _hasPrevious != hasPrevious) {
      _controller?.dispose();
      _currentSongId = currentSong.id;
      _hasPrevious = hasPrevious;
      final initialPage = hasPrevious ? 1 : 0;
      _controller = PageController(initialPage: initialPage);
    }

    return ClipRRect(
      borderRadius: AppRadius.mdBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
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
                  child: const PlayerScreen(),
                );
              },
            );
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdBorderRadius,
              color: AppColors.surface.withValues(alpha: 0.65),
              border: Border.all(color: AppColors.hairlineLight, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s3 * 0.8,
              vertical: AppSpacing.s3 * 0.8,
            ),
            child: Row(
              children: [
                AlbumArtCover(
                  seed: songTitle,
                  size: 56,
                  radius: AppRadius.sm,
                  child:
                      currentSong.thumbnail != null &&
                          currentSong.thumbnail!.isNotEmpty
                      ? Image.network(
                          currentSong.thumbnail!,
                          cacheWidth: thumbCacheWidth(context, 56),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: PageView(
                      key: ValueKey(_currentSongId),
                      controller: _controller!,
                      onPageChanged: (value) {
                        final currentPageIndex = previousSong != null ? 1 : 0;
                        if (value > currentPageIndex) {
                          ref.read(playbackProvider.notifier).playNext();
                        } else if (value < currentPageIndex) {
                          ref.read(playbackProvider.notifier).playPrevious();
                        }
                      },
                      children: [
                        if (previousSong != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                previousSong.title,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                previousSong.artists
                                        ?.map((e) => e.name)
                                        .join(', ') ??
                                    'Unknown Artist',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              songTitle,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              artistsName,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (nextSong != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                nextSong.title,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                nextSong.artists
                                        ?.map((e) => e.name)
                                        .join(', ') ??
                                    'Unknown Artist',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 4,
                  children: [
                    IconButton(
                      onPressed: hasPrevious
                          ? () => ref
                                .read(playbackProvider.notifier)
                                .playPrevious()
                          : null,
                      icon: Icon(
                        Icons.skip_previous,
                        color: hasPrevious
                            ? AppColors.text
                            : AppColors.text2.withValues(alpha: 0.3),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(playbackProvider.notifier).togglePlay(),
                      icon: Icon(
                        playback.playing ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      onPressed: hasNext
                          ? () => ref.read(playbackProvider.notifier).playNext()
                          : null,
                      icon: Icon(
                        Icons.skip_next,
                        color: hasNext
                            ? AppColors.text
                            : AppColors.text2.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
