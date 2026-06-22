import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/repositories/artist_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/song_options_bottom_sheet.dart';
import 'package:vibez/presentation/common/skeleton.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class ArtistSongsScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String browseId;

  const ArtistSongsScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.browseId,
  });

  @override
  ConsumerState<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends ConsumerState<ArtistSongsScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final songs = await ArtistRepository.instance.getArtistSongs(
        widget.artistId,
        widget.browseId,
      );
      if (mounted) {
        setState(() {
          _songs = songs ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load songs.';
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

  void _showMoreSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(
        song: SearchSong(
          id: song.id,
          title: song.title,
          album: song.album?.title ?? '',
          duration: song.duration,
          thumbnail: song.thumbnail ?? '',
          artists: song.artists?.map((a) => a.name).join(', ') ?? widget.artistName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          widget.artistName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
              onPressed: () {
                ref.read(playbackProvider.notifier).playSongsFromList(_songs, 0);
                ref.read(playbackProvider.notifier).setCurrentlyPlaying(CurrentlyPlaying(
                  type: PlayingSourceType.artist,
                  sourceId: widget.artistId,
                  sourceName: widget.artistName,
                ));
              },
            ),
        ],
      ),
      body: _buildBody(userState),
    );
  }

  Widget _buildBody(dynamic userState) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              spacing: AppSpacing.s3,
              children: [
                const Skeleton(height: 52, width: 52, borderRadius: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(height: 14, width: 160, borderRadius: 4),
                      const SizedBox(height: 8),
                      const Skeleton(height: 12, width: 100, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSongs,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text('No songs found.', style: TextStyle(color: AppColors.text2)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        final isSongLiked =
            userState?.likedSongs?.any((s) => s.id == song.id) ?? false;
        final songArtistsStr =
            song.artists?.map((a) => a.name).join(', ') ?? widget.artistName;

        return InkWell(
          onTap: () {
            ref.read(playbackProvider.notifier).playSongsFromList(_songs, index);
            ref.read(playbackProvider.notifier).setCurrentlyPlaying(CurrentlyPlaying(
              type: PlayingSourceType.artist,
              sourceId: widget.artistId,
              sourceName: widget.artistName,
            ));
          },
          borderRadius: AppRadius.smBorderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AlbumArtCover(
                  seed: song.title,
                  size: 52,
                  radius: 10,
                  child: song.thumbnail != null && song.thumbnail!.isNotEmpty
                      ? Image.network(
                          song.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    isSongLiked ? Icons.favorite : Icons.favorite_border,
                    color: isSongLiked ? AppColors.danger : AppColors.text3,
                  ),
                  onPressed: () {
                    ref.read(userProvider.notifier).likeSong(song.id);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.text3),
                  onPressed: () => _showMoreSheet(context, song),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
