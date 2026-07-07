import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/provider/playback_provider.dart';

class SongOptionsBottomSheet extends ConsumerWidget {
  final SearchSong song;

  const SongOptionsBottomSheet({super.key, required this.song});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final isLiked = userState?.likedSongs?.any((s) => s.id == song.id) ?? false;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: AppColors.hairlineLight, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.text3.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.hairlineLight,
                      padding: const EdgeInsets.all(8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.text,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    AlbumArtCover(
                      seed: song.title,
                      size: 64,
                      radius: 12,
                      child: song.thumbnail.isNotEmpty
                          ? Image.network(
                              song.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${song.artists} • ${_formatDuration(song.duration)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.text2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.hairlineLight, height: 1),
              const SizedBox(height: 12),

              _buildOptionTile(
                context,
                icon: Icons.play_arrow_rounded,
                title: 'Play now',
                onTap: () {
                  Navigator.pop(context);
                  ref.read(playbackProvider.notifier).playSongById(song.id);
                },
              ),
              _buildOptionTile(
                context,
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                title: isLiked ? 'Unlike' : 'Like',
                iconColor: isLiked ? AppColors.danger : AppColors.text,
                onTap: () {
                  ref.read(userProvider.notifier).likeSong(song.id);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.playlist_add,
                title: 'Add to queue',
                onTap: () async {
                  final fetchedSong = await ref
                      .read(songCacheProvider.notifier)
                      .fetchSong(song.id);
                  ref.read(playbackProvider.notifier).addToQueue(fetchedSong!);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.playlist_add,
                title: 'Add to playlist',
                onTap: () {
                  _showPlaylistSelector(context, ref);
                },
              ),
              _buildOptionTile(
                context,
                icon: Icons.ios_share_rounded,
                title: 'Share',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    final userState = ref.read(userProvider);
    final playlists = userState?.playlists ?? [];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(
              top: BorderSide(color: AppColors.hairlineLight, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.text3.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Add to playlist",
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/playlist-add');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: AppRadius.pillBorderRadius,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "New",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (playlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          color: AppColors.text3.withValues(alpha: 0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "No playlists yet",
                          style: TextStyle(
                            color: AppColors.text3,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      itemCount: playlists.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final songCount = playlist.songs?.length ?? 0;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppRadius.smBorderRadius,
                            onTap: () async {
                              Navigator.pop(context);
                              final success = await ref
                                  .read(userProvider.notifier)
                                  .addSongToPlaylist(
                                    playlistId: playlist.id,
                                    songId: song.id,
                                  );
                              AppSnackbar.show(
                                message: success
                                    ? "Added to '${playlist.name}'"
                                    : "Failed to add song.",
                                type: success
                                    ? AppSnackType.success
                                    : AppSnackType.error,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  AlbumArtCover(
                                    seed: playlist.name,
                                    size: 46,
                                    radius: 10,
                                    child: playlist.thumbnail != null &&
                                            playlist.thumbnail!.isNotEmpty
                                        ? Image.network(
                                            playlist.thumbnail!,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.name,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                                          style: const TextStyle(
                                            color: AppColors.text3,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppColors.text3,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.text,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
