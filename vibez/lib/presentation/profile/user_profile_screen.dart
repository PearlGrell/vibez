import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/user.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/repositories/user_repository.dart';
import 'package:vibez/data/repositories/room_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/details_skeleton.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/presentation/profile/profile_screen.dart';

final userRoomsProvider = FutureProvider.family<List<Room>, String>((ref, userId) async {
  return await RoomRepository.instance.getUserRooms(userId);
});

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await UserRepository.instance.getUser(widget.userId);
      if (mounted) {
        final me = ref.read(userProvider);
        setState(() {
          _user = user;
          _isLoading = false;
          _isFollowing =
              me?.following?.any((u) => u.id == widget.userId) ?? false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);

    final success = _isFollowing
        ? await UserRepository.instance.unfollowUser(widget.userId)
        : await UserRepository.instance.followUser(widget.userId);

    if (success && mounted) {
      setState(() => _isFollowing = !_isFollowing);
      ref.read(userProvider.notifier).fetchMe();
    }
    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const DetailsSkeleton();

    if (_errorMessage != null || _user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppIconButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            _errorMessage ?? 'User not found.',
            style: const TextStyle(color: AppColors.text2, fontSize: 16),
          ),
        ),
      );
    }

    final profile = _user!;
    final profileUrl = profile.profileUrl;

    final profileColor =
        profileUrl != null && profileUrl.startsWith('default://')
            ? Color(
                int.parse(
                  'FF${profileUrl.replaceFirst('default://', '')}',
                  radix: 16,
                ),
              )
            : const Color(0xFF8B5CF6);

    final textColor = Color.lerp(profileColor, Colors.black, 0.7)!;

    final hasImage = profileUrl != null &&
        profileUrl.isNotEmpty &&
        !profileUrl.startsWith('default://');

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.widthOf(context) / 2,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  AlbumArtCover(
                    seed: profile.name,
                    size: double.infinity,
                    radius: 0,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.4, 1.0],
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.6),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.s4,
                    top: MediaQuery.paddingOf(context).top + 8,
                    child: AppIconButton(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.s4,
                    top: (MediaQuery.widthOf(context) - 108) / 2,
                    child: Container(
                      height: 108,
                      width: 108,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                      ),
                      padding: const EdgeInsets.all(4),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? ClipOval(
                              child: Image.network(
                                profileUrl,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                errorBuilder: (_, _, _) => _buildAvatar(
                                    context, profile, profileColor, textColor),
                              ),
                            )
                          : _buildAvatar(
                              context, profile, profileColor, textColor),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                54 + AppSpacing.s1,
                AppSpacing.s4,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text(
                              profile.name,
                              style:
                                  Theme.of(context).textTheme.displaySmall,
                            ),
                            Text('@${profile.username ?? 'user'}'),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _followLoading ? null : _toggleFollow,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isFollowing
                                ? AppColors.surface
                                : AppColors.primary,
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: _isFollowing
                                    ? AppColors.hairlineDark
                                    : AppColors.primary,
                              ),
                            ),
                            borderRadius: AppRadius.pillBorderRadius,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s4,
                            vertical: AppSpacing.s2,
                          ),
                          child: _followLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.text,
                                  ),
                                )
                              : Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s3),
                    SizedBox(
                      width: double.infinity,
                      child: Text(profile.bio!),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt.withValues(alpha: 0.5),
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.surface),
                    ),
                    child: ProfileStatsCard(
                      followers: profile.followers?.length ?? 0,
                      following: profile.following?.length ?? 0,
                      rooms: profile.joinedRooms?.length ?? 0,
                    ),
                  ),
                  if (profile.tags != null && profile.tags!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      'Favourite genres',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text2,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Wrap(
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s2,
                      children: profile.tags!.map((e) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.s4,
                            vertical: AppSpacing.s2 * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt.withValues(alpha: 0.5),
                            borderRadius: AppRadius.lgBorderRadius,
                            border: Border.all(color: AppColors.cardAlt),
                          ),
                          child: Text(
                            e,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text2,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (profile.playlists != null &&
                      profile.playlists!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      'Playlists',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: profile.playlists!.length,
                        itemBuilder: (context, index) {
                          final playlist = profile.playlists![index];
                          return GestureDetector(
                            onTap: () =>
                                context.push('/playlist/${playlist.id}'),
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AlbumArtCover(
                                    seed: playlist.name,
                                    size: 110,
                                    radius: AppRadius.sm,
                                    child: playlist.thumbnail != null &&
                                            playlist.thumbnail!.isNotEmpty
                                        ? Image.network(playlist.thumbnail!,
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    playlist.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
                  ],
                  if (profile.likedAlbums != null &&
                      profile.likedAlbums!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    const Text(
                      'Albums',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: profile.likedAlbums!.length,
                        itemBuilder: (context, index) {
                          final album = profile.likedAlbums![index];
                          return GestureDetector(
                            onTap: () => context.push('/album/${album.id}'),
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AlbumArtCover(
                                    seed: album.title,
                                    size: 110,
                                    radius: AppRadius.sm,
                                    child: album.thumbnail != null &&
                                            album.thumbnail!.isNotEmpty
                                        ? Image.network(album.thumbnail!,
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    album.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
                  ],
                  if (profile.followedArtists != null &&
                      profile.followedArtists!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    const Text(
                      'Artists',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: profile.followedArtists!.length,
                        itemBuilder: (context, index) {
                          final artist = profile.followedArtists![index];
                          return GestureDetector(
                            onTap: () =>
                                context.push('/artist/${artist.id}'),
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 110,
                                    width: 110,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle),
                                    clipBehavior: Clip.antiAlias,
                                    child: AlbumArtCover(
                                      seed: artist.name,
                                      size: 110,
                                      radius: 55,
                                      child: artist.thumbnail != null &&
                                              artist.thumbnail!.isNotEmpty
                                          ? Image.network(artist.thumbnail!,
                                              fit: BoxFit.cover)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    artist.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
                  ],

                // My Rooms
                ...ref.watch(userRoomsProvider(profile.id)).when(
                  data: (userRooms) {
                    if (userRooms.isEmpty) return [];
                    return [
                      const SizedBox(height: AppSpacing.s4),
                      const Text(
                        "My Rooms",
                        style: TextStyle(
                            color: AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: userRooms.length,
                          itemBuilder: (context, index) {
                            final room = userRooms[index];
                            return GestureDetector(
                              onTap: () {
                                context.push('/room/${room.id}');
                              },
                              child: Container(
                                width: 110,
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Stack(
                                      children: [
                                        AlbumArtCover(
                                          seed: room.name,
                                          size: 110,
                                          radius: AppRadius.sm,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Icon(
                                            Icons.podcasts_rounded,
                                            color: AppColors.generateTextColor(room.name),
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      room.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
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
                    ];
                  },
                  loading: () => [
                    const SizedBox(height: AppSpacing.s4),
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ],
                  error: (_, _) => [],
                ),
                const SizedBox(height: 140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    User profile,
    Color profileColor,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: profileColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: textColor,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
