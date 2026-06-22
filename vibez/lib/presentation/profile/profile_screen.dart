import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProvider);

    final profileUrl = profile!.profileUrl;

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

    final hasImage =
        profileUrl != null &&
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
              clipBehavior: .none,
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
                  top: (MediaQuery.widthOf(context) - 108) / 2,
                  child: Container(
                    height: 108,
                    width: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                    ),
                    padding: EdgeInsets.all(4),
                    clipBehavior: .antiAlias,
                    child: hasImage
                        ? Image.network(
                            profileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: profileColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  profile.name.isNotEmpty
                                      ? profile.name[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: textColor,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: profileColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : '?',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: textColor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
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
              crossAxisAlignment: .start,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: .start,
                      spacing: 4,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text("@${profile.username ?? 'user'}"),
                      ],
                    ),

                    GestureDetector(
                      onTap: () {
                        context.push('/edit-profile');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.hairlineDark),
                          ),
                          borderRadius: AppRadius.pillBorderRadius,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4,
                          vertical: AppSpacing.s2,
                        ),
                        child: Row(
                          spacing: AppSpacing.s2 * 0.85,
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 18,
                              color: AppColors.text,
                            ),
                            Text(
                              "Edit",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s3),

                SizedBox(width: double.infinity, child: Text(profile.bio!)),

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

                const SizedBox(height: AppSpacing.s6),

                Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      "Favourite genres",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text2,
                          ),
                    ),
                    SizedBox(height: AppSpacing.s3),
                    Wrap(
                      direction: Axis.horizontal,
                      spacing: AppSpacing.s2,
                      runSpacing: AppSpacing.s2,
                      children: [
                        ...profile.tags!.map((e) {
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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text2,
                                  ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s6),

                // Library Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your Library",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                      onPressed: () {
                        context.push('/playlist-add');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),

                // Playlists Row
                const Text(
                  "Playlists",
                  style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.s2),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Liked Songs card
                      GestureDetector(
                        onTap: () {
                          context.push('/playlist/liked-songs');
                        },
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 110,
                                width: 110,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: AppRadius.smBorderRadius,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.favorite, color: Colors.white, size: 44),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Liked Songs",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Created Playlists
                      ...?profile.playlists?.map((playlist) {
                        return GestureDetector(
                          onTap: () {
                            context.push('/playlist/${playlist.id}');
                          },
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
                                  child: playlist.thumbnail != null && playlist.thumbnail!.isNotEmpty
                                      ? Image.network(playlist.thumbnail!, fit: BoxFit.cover)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  playlist.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Liked Playlists
                      ...?profile.likedPlaylists?.map((playlist) {
                        return GestureDetector(
                          onTap: () {
                            context.push('/playlist/${playlist.id}');
                          },
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
                                  child: playlist.thumbnail != null && playlist.thumbnail!.isNotEmpty
                                      ? Image.network(playlist.thumbnail!, fit: BoxFit.cover)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  playlist.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Liked Albums
                if (profile.likedAlbums != null && profile.likedAlbums!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  const Text(
                    "Albums",
                    style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.bold, fontSize: 16),
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
                          onTap: () {
                            context.push('/album/${album.id}');
                          },
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
                                  child: album.thumbnail != null && album.thumbnail!.isNotEmpty
                                      ? Image.network(album.thumbnail!, fit: BoxFit.cover)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  album.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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

                // Followed Artists
                if (profile.followedArtists != null && profile.followedArtists!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  const Text(
                    "Artists",
                    style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.bold, fontSize: 16),
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
                          onTap: () {
                            context.push('/artist/${artist.id}');
                          },
                          child: Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 110,
                                  width: 110,
                                  decoration: const BoxDecoration(shape: BoxShape.circle),
                                  clipBehavior: Clip.antiAlias,
                                  child: AlbumArtCover(
                                    seed: artist.name,
                                    size: 110,
                                    radius: 55,
                                    child: artist.thumbnail != null && artist.thumbnail!.isNotEmpty
                                        ? Image.network(artist.thumbnail!, fit: BoxFit.cover)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  artist.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                const SizedBox(height: 140),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class ProfileStatsCard extends StatelessWidget {
  final int followers;
  final int following;
  final int rooms;

  const ProfileStatsCard({
    super.key,
    required this.followers,
    required this.following,
    required this.rooms,
  });

  Widget _buildStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 0.75,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.text3,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          _buildStat(context, followers.toString(), 'Followers'),
          _divider(),
          _buildStat(context, following.toString(), 'Following'),
          _divider(),
          _buildStat(context, rooms.toString(), 'Rooms'),
        ],
      ),
    );
  }
}
