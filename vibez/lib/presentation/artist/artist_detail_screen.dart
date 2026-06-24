import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/artist.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/repositories/artist_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/song_options_bottom_sheet.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/presentation/common/details_skeleton.dart';
import 'package:vibez/presentation/common/search_song_helper.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  Artist? _artist;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchArtist();
  }

  Future<void> _fetchArtist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final artist = await ArtistRepository.instance.getArtist(widget.artistId);
      if (mounted) {
        setState(() {
          _artist = artist;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load artist details.";
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

  void _showMoreSheet(BuildContext context, Song song, String artistName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SongOptionsBottomSheet(
        song: SearchSongHelper.fromSong(song, artistName: artistName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    if (_isLoading) {
      return const DetailsSkeleton(isArtist: true);
    }

    if (_errorMessage != null || _artist == null) {
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
            _errorMessage ?? "Artist details not found.",
            style: const TextStyle(color: AppColors.text2, fontSize: 16),
          ),
        ),
      );
    }

    final artist = _artist!;
    final isFollowing =
        userState?.followedArtists?.any((a) => a.id == artist.id) ?? false;
    final popularSongs = artist.songs ?? [];
    final albums = artist.albums ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AlbumArtCover(
                      seed: artist.name,
                      size: 140,
                      radius: 70,
                      child:
                          artist.thumbnail != null &&
                              artist.thumbnail!.isNotEmpty
                          ? Image.network(
                              artist.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        artist.name,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "${artist.monthlyListeners ?? artist.subscribers ?? '38.2M'} monthly listeners",
                    style: const TextStyle(
                      color: AppColors.text2,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
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
                      const SizedBox(width: 8),

                      OutlinedButton(
                        onPressed: () {
                          if (isFollowing) {
                            ref
                                .read(userProvider.notifier)
                                .unfollowArtist(artist.id);
                          } else {
                            ref
                                .read(userProvider.notifier)
                                .followArtist(artist);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.hairlineDark),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          isFollowing ? "Following" : "Follow",
                          style: TextStyle(
                            color: isFollowing ? AppColors.text2 : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (popularSongs.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(playbackProvider.notifier)
                                .playSongsFromList(popularSongs, 0);
                            ref
                                .read(playbackProvider.notifier)
                                .setCurrentlyPlaying(
                                  CurrentlyPlaying(
                                    type: PlayingSourceType.artist,
                                    sourceId: artist.id,
                                    sourceName: artist.name,
                                    thumbnail: artist.thumbnail,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          if (popularSongs.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Popular",
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    if (artist.songsBrowseId != null &&
                        artist.songsBrowseId!.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          context.push(
                            '/artist/${artist.id}/songs',
                            extra: {
                              'artistName': artist.name,
                              'browseId': artist.songsBrowseId!,
                            },
                          );
                        },
                        child: const Text(
                          "See all",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = popularSongs[index];
                  final isSongLiked =
                      userState?.likedSongs?.any((s) => s.id == song.id) ??
                      false;
                  final songArtistsStr =
                      song.artists?.map((a) => a.name).join(', ') ??
                      artist.name;

                  return Container(
                    key: ValueKey(song.id),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(playbackProvider.notifier)
                            .playSongsFromList(popularSongs, index);
                        ref
                            .read(playbackProvider.notifier)
                            .setCurrentlyPlaying(
                              CurrentlyPlaying(
                                type: PlayingSourceType.artist,
                                sourceId: artist.id,
                                sourceName: artist.name,
                                thumbnail: artist.thumbnail,
                              ),
                            );
                      },
                      borderRadius: AppRadius.smBorderRadius,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                  _showMoreSheet(context, song, artist.name),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: popularSongs.length > 5 ? 5 : popularSongs.length),
              ),
            ),
          ],

          if (albums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.s4,
                  right: AppSpacing.s4,
                  top: 24,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Albums",
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    if (artist.albumsParams != null &&
                        artist.albumsParams!.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          context.push(
                            '/artist/${artist.id}/albums',
                            extra: {
                              'artistName': artist.name,
                              'browseId': artist.albumsBrowseId ?? '',
                              'params': artist.albumsParams!,
                            },
                          );
                        },
                        child: const Text(
                          "See all",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return GestureDetector(
                      onTap: () {
                        context.push('/album/${album.id}');
                      },
                      child: Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AlbumArtCover(
                              seed: album.title,
                              size: 130,
                              radius: AppRadius.sm,
                              child:
                                  album.thumbnail != null &&
                                      album.thumbnail!.isNotEmpty
                                  ? Image.network(
                                      album.thumbnail!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              album.title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${album.year ?? ''} • ${album.type ?? 'Album'}",
                              style: const TextStyle(
                                color: AppColors.text3,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
