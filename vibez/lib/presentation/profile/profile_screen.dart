import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/data/models/user.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onBack;
  const ProfileScreen({super.key, required this.onBack});

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(userProvider.notifier).fetchMe();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.text),
                                  ),
                                ],
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

                      const SizedBox(height: AppSpacing.s6),

                      if (profile.tags != null && profile.tags!.isNotEmpty)
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
                                      color: AppColors.cardAlt.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: AppRadius.lgBorderRadius,
                                      border: Border.all(
                                        color: AppColors.cardAlt,
                                      ),
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
                                }),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: AppSpacing.s6),

                      LibrarySection(profile: profile),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

enum LibraryFilter { all, playlists, albums, artists, rooms }

enum LibraryItemType {
  likedSongs,
  history,
  playlist,
  album,
  artist,
  myRoom,
  followedRoom,
}

class LibraryItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final LibraryItemType type;
  final VoidCallback onTap;

  LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    required this.onTap,
  });
}

class LibrarySection extends ConsumerStatefulWidget {
  final User profile;
  const LibrarySection({super.key, required this.profile});

  @override
  ConsumerState<LibrarySection> createState() => _LibrarySectionState();
}

class _LibrarySectionState extends ConsumerState<LibrarySection> {
  LibraryFilter _filter = LibraryFilter.all;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    final items = <LibraryItem>[
      LibraryItem(
        id: 'liked-songs',
        title: 'Liked Songs',
        subtitle: '${profile.likedSongs?.length ?? 0} songs',
        type: LibraryItemType.likedSongs,
        onTap: () => context.push('/playlist/liked-songs'),
      ),
      LibraryItem(
        id: 'history',
        title: 'History',
        subtitle:
            '${ref.watch(playbackProvider).recentlyPlayed.length} songs',
        type: LibraryItemType.history,
        onTap: () => context.push('/playlist/history'),
      ),
      if (profile.playlists != null)
        ...profile.playlists!.map(
          (p) => LibraryItem(
            id: p.id,
            title: p.name,
            subtitle: 'Playlist • ${profile.name}',
            imageUrl: p.thumbnail,
            type: LibraryItemType.playlist,
            onTap: () => context.push('/playlist/${p.id}'),
          ),
        ),
      if (profile.likedPlaylists != null)
        ...profile.likedPlaylists!.map(
          (p) => LibraryItem(
            id: p.id,
            title: p.name,
            subtitle: 'Playlist',
            imageUrl: p.thumbnail,
            type: LibraryItemType.playlist,
            onTap: () => context.push('/playlist/${p.id}'),
          ),
        ),
      if (profile.likedAlbums != null)
        ...profile.likedAlbums!.map(
          (a) => LibraryItem(
            id: a.id,
            title: a.title,
            subtitle: 'Album',
            imageUrl: a.thumbnail,
            type: LibraryItemType.album,
            onTap: () => context.push('/album/${a.id}'),
          ),
        ),
      if (profile.followedArtists != null)
        ...profile.followedArtists!.map(
          (a) => LibraryItem(
            id: a.id,
            title: a.name,
            subtitle: 'Artist',
            imageUrl: a.thumbnail,
            type: LibraryItemType.artist,
            onTap: () => context.push('/artist/${a.id}'),
          ),
        ),
      if (profile.myRooms != null)
        ...profile.myRooms!.map(
          (r) => LibraryItem(
            id: r.id,
            title: r.name,
            subtitle: 'My Room',
            type: LibraryItemType.myRoom,
            onTap: () => context.push('/room/${r.id}'),
          ),
        ),
      if (profile.joinedRooms != null)
        ...profile.joinedRooms!
            .where(
              (r) =>
                  r.createdById != profile.id && r.createdBy?.id != profile.id,
            )
            .map(
              (r) => LibraryItem(
                id: r.id,
                title: r.name,
                subtitle: 'Room • ${r.createdBy?.name ?? "Unknown"}',
                type: LibraryItemType.followedRoom,
                onTap: () => context.push('/room/${r.id}'),
              ),
            ),
    ];

    final filteredItems = items.where((item) {
      switch (_filter) {
        case LibraryFilter.all:
          return true;
        case LibraryFilter.playlists:
          return item.type == LibraryItemType.playlist ||
              item.type == LibraryItemType.likedSongs ||
              item.type == LibraryItemType.history;
        case LibraryFilter.albums:
          return item.type == LibraryItemType.album;
        case LibraryFilter.artists:
          return item.type == LibraryItemType.artist;
        case LibraryFilter.rooms:
          return item.type == LibraryItemType.myRoom ||
              item.type == LibraryItemType.followedRoom;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Library",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: AppColors.text2,
                  ),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    context.push('/playlist-add');
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: LibraryFilter.values.map((filter) {
              final isSelected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ChoiceChip(
                  label: Text(
                    filter.name[0].toUpperCase() + filter.name.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text2,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.hairlineDark,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        if (filteredItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(
              child: Text(
                "Nothing here yet",
                style: TextStyle(color: AppColors.text2, fontSize: 16),
              ),
            ),
          )
        else if (_isGridView)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return _buildGridItem(filteredItems[index]);
            },
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return _buildListItem(filteredItems[index]);
            },
          ),
      ],
    );
  }

  Widget _buildGridItem(LibraryItem item) {
    final isCircle = item.type == LibraryItemType.artist;

    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        crossAxisAlignment: isCircle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _buildImage(item, size: double.infinity),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isCircle ? TextAlign.center : TextAlign.left,
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(color: AppColors.text2, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isCircle ? TextAlign.center : TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(LibraryItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: AppRadius.smBorderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildImage(item),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
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
            const Icon(Icons.more_vert_rounded, color: AppColors.text3),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(LibraryItem item, {double? size}) {
    if (item.type == LibraryItemType.likedSongs ||
        item.type == LibraryItemType.history) {
      final isHistory = item.type == LibraryItemType.history;
      return Container(
        width: size ?? 64,
        height: size ?? 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isHistory
                ? const [Color(0xFF6366F1), Color(0xFF06B6D4)]
                : const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: size == null
              ? AppRadius.smBorderRadius
              : BorderRadius.circular(16),
          boxShadow: size != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Icon(
          isHistory ? Icons.history_rounded : Icons.favorite,
          color: Colors.white,
          size: size != null ? 48 : 28,
        ),
      );
    }

    final isCircle = item.type == LibraryItemType.artist;
    final radius = isCircle ? 1000.0 : (size != null ? 16.0 : AppRadius.sm);

    return Container(
      width: size ?? 64,
      height: size ?? 64,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        boxShadow: size != null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AlbumArtCover(
            seed: item.title,
            size: size ?? 64,
            radius: radius,
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                : null,
          ),
          if (item.type == LibraryItemType.myRoom ||
              item.type == LibraryItemType.followedRoom)
            Positioned(
              bottom: size != null ? 8 : 4,
              right: size != null ? 8 : 4,
              child: Container(
                padding: EdgeInsets.all(size != null ? 6 : 4),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.type == LibraryItemType.myRoom
                      ? Icons.podcasts_rounded
                      : Icons.headset_mic_rounded,
                  color: Colors.white,
                  size: size != null ? 18 : 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
