import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/queue_item.dart';
import 'package:vibez/data/models/request_item.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/user.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/data/provider/room_playback_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/services/player_audio_service.dart';
import 'package:vibez/data/repositories/search_repository.dart';
import 'package:vibez/presentation/common/skeleton.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class DjControlScreen extends ConsumerStatefulWidget {
  final String roomId;
  const DjControlScreen({super.key, required this.roomId});

  @override
  ConsumerState<DjControlScreen> createState() => _DjControlScreenState();
}

class _DjControlScreenState extends ConsumerState<DjControlScreen> {
  int _selectedTab = 0;
  final Set<String> _loadingDjUserIds = {};

  @override
  Widget build(BuildContext context) {
    ref.watch(roomPlaybackProvider);
    final roomRef = ref.watch(roomProvider(widget.roomId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, roomRef),
            const SizedBox(height: AppSpacing.s4),
            _buildTabBar(context, roomRef),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: _selectedTab == 0
                  ? _buildBoothTab(context, roomRef)
                  : _buildRequestsTab(context, roomRef),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RoomProvider roomRef) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.s1, AppSpacing.s4, 0),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.chevron_left,
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DJ CONTROL',
                  style: TextStyle(
                    color: AppColors.text2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roomRef.room?.name ?? "",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s1 + 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1215),
              border: Border.all(color: const Color(0xFF6B2428)),
              borderRadius: AppRadius.pillBorderRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, size: 8, color: Color(0xFFD14948)),
                SizedBox(width: 5),
                Text(
                  'ON AIR',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, RoomProvider roomRef) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(child: _buildTab('Booth', 0)),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: _buildTab('Requests · ${roomRef.requestItems.length + roomRef.djRequests.length}', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: isSelected ? null : Border.all(color: AppColors.hairlineDark),
          borderRadius: AppRadius.mdBorderRadius,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.text : AppColors.text2,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoothTab(BuildContext context, RoomProvider roomRef) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNowPlaying(context, roomRef),
          const SizedBox(height: AppSpacing.s4),
          _buildLeaveAsDjButton(context, roomRef),
          const SizedBox(height: AppSpacing.s7),
          _buildUpNextHeader(context, roomRef),
          const SizedBox(height: AppSpacing.s3),
          ...roomRef.queue.asMap().entries.map(
            (entry) => _buildQueueItem(
              context,
              entry.key,
              entry.value,
              () async {
                await roomRef.playItem(entry.value);
              },
              () async {
                await roomRef.removeSong(entry.value.id);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          _buildRecommendationHeader(context, roomRef),
          const SizedBox(height: AppSpacing.s3),

          if (roomRef.recommendationState == RecommendationState.loading ||
              roomRef.recommendationState == RecommendationState.initial)
            ...List.generate(
              3,
              (index) => _buildRecommendationSkeletonItem(index),
            ),

          if (roomRef.recommendationState == RecommendationState.success)
            for (final (index, song) in roomRef.recommendations.indexed)
              _buildRecommendationItem(
                context,
                index,
                song,
                () async {
                  await roomRef.songChanged(song.id);
                  roomRef.removeRecommendation(song.id);
                },
                () async {
                  await roomRef.addSong(song.id);
                  roomRef.removeRecommendation(song.id);
                },
              ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildNowPlaying(BuildContext context, RoomProvider roomRef) {
    final currentSong = roomRef.room?.currentSong;
    if (currentSong == null) {
      return _buildEmptyState(context);
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.hairlineDark),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  AlbumArtCover(
                    seed: currentSong.title,
                    size: 56,
                    radius: AppRadius.sm,
                    child:
                        currentSong.thumbnail != null &&
                            currentSong.thumbnail!.isNotEmpty
                        ? Image.network(
                            currentSong.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: AppSpacing.s2,
                    left: AppSpacing.s2,
                    child: EqualizerBars(
                      color: Colors.white,
                      barCount: 4,
                      barWidth: 3,
                      barSpacing: 2,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentSong.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentSong.artists?.map((e) => e.name).join(",") ??
                          "Unknown Artist",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          StreamBuilder<Duration>(
            stream: PlayerAudioService.roomHandler.positionStream,
            builder: (context, snapshot) {
              final currentSong = roomRef.room?.currentSong;
              final durationSec = currentSong?.duration ?? 0;

              final position = snapshot.data ?? Duration.zero;
              final elapsedSec = position.inSeconds.clamp(0, durationSec);
              final progress = durationSec == 0
                  ? 0.0
                  : elapsedSec / durationSec;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.card,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(Duration(seconds: elapsedSec)),
                        style: const TextStyle(
                          color: AppColors.text2,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(Duration(seconds: durationSec)),
                        style: const TextStyle(
                          color: AppColors.text2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(child: _buildPlayNextButton(context, roomRef)),
              const SizedBox(width: AppSpacing.s3),
              Expanded(child: _buildStopButton(context, roomRef)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s8,
          horizontal: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardAlt),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              child: const Icon(
                Icons.headphones_outlined,
                size: 28,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              "This room is quiet",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              "Nothing's playing right now. Step in to\nstart the music and others can join you.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpNextHeader(BuildContext context, RoomProvider roomRef) {
    return Row(
      children: [
        const Icon(Icons.queue_music_rounded, color: AppColors.text, size: 22),
        const SizedBox(width: AppSpacing.s2),
        Text(
          'Up next',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          '${roomRef.queue.length}/5',
          style: const TextStyle(color: AppColors.text2, fontSize: 14),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showAddToQueueSheet(context, roomRef),
          child: Row(
            children: const [
              Icon(Icons.add, color: AppColors.text, size: 18),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationHeader(
    BuildContext context,
    RoomProvider roomRef,
  ) {
    return Row(
      children: [
        const Icon(Icons.recommend_outlined, color: AppColors.text, size: 22),
        const SizedBox(width: AppSpacing.s2),
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    int index,
    QueueItem item,
    Function() onTap,
    Function() onRemove,
  ) {
    final isDj = item.addedBy.id == ref.watch(userProvider)?.id;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.hairlineDark),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text2,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            AlbumArtCover(
              seed: item.song.title,
              size: 56,
              radius: AppRadius.sm,
              child:
                  item.song.thumbnail != null && item.song.thumbnail!.isNotEmpty
                  ? Image.network(
                      item.song.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.song.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text:
                          item.song.artists?.map((e) => e.name).join(",") ??
                          "Unknown Artist",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                      children: [
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: isDj
                              ? 'added by DJ'
                              : 'req @${item.addedBy.username}',
                          style: const TextStyle(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildSmallIconButton(
              icon: Icons.delete_outline,
              color: AppColors.danger,
              onTap: () async {
                await onRemove();
                AppSnackbar.show(
                  message: "Removed ${item.song.title} from Queue",
                  type: AppSnackType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    int index,
    Song song,
    Function() onTap,
    Function() onAdd,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.hairlineDark),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text2,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            AlbumArtCover(
              seed: song.title,
              size: 56,
              radius: AppRadius.sm,
              child: song.thumbnail != null && song.thumbnail!.isNotEmpty
                  ? Image.network(
                      song.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      text:
                          song.artists?.map((e) => e.name).join(",") ??
                          "Unknown Artist",
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                    ),
                  ),
                ],
              ),
            ),
            _buildSmallIconButton(
              icon: Icons.add_rounded,
              color: AppColors.text2,
              onTap: () async {
                await onAdd();
                AppSnackbar.show(
                  message: "Added ${song.title} to Queue",
                  type: AppSnackType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSkeletonItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.hairlineDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text2,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          const Skeleton(height: 56, width: 56, borderRadius: AppRadius.sm),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(height: 16, width: 140, borderRadius: 4),
                SizedBox(height: 8),
                Skeleton(height: 12, width: 80, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          const Padding(
            padding: EdgeInsets.all(6),
            child: Skeleton(height: 22, width: 22, borderRadius: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context, RoomProvider roomRef) {
    final requests = roomRef.requestItems;
    final djRequests = roomRef.djRequests;

    if (requests.isEmpty && djRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s8,
              horizontal: AppSpacing.s6,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardAlt),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                  child: const Icon(
                    Icons.front_hand_outlined,
                    size: 28,
                    color: AppColors.text2,
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  "No requests yet",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  "When listeners request a track or\nthe booth, it'll show up here for you to accept.",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (djRequests.isNotEmpty) ...[
            Text(
              'Listeners want to take over the booth.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
            ),
            const SizedBox(height: AppSpacing.s4),
            ...djRequests.map((u) => _buildDjRequestCard(context, u, roomRef)),
            const SizedBox(height: AppSpacing.s6),
          ],
          if (requests.isNotEmpty) ...[
            Text(
              'Listeners are requesting tracks. Accept to drop them into the queue.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
            ),
            const SizedBox(height: AppSpacing.s4),
            ...requests.map((r) => _buildRequestCard(context, r, roomRef)),
          ],
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildDjRequestCard(
    BuildContext context,
    User user,
    RoomProvider roomRef,
  ) {
    final avatarColor = AppColors.generateBgColor(user.name);
    final isLoadingThis = _loadingDjUserIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairlineDark),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.bg,
            ),
            child: Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.generateTextColor(user.name),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.username != null)
                  Text(
                    '@${user.username}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                  ),
              ],
            ),
          ),
          _buildCircleActionButton(
            icon: Icons.close,
            backgroundColor: AppColors.card,
            iconColor: AppColors.text2,
            onTap: () {
              roomRef.rejectDjRequest(user.id);
              AppSnackbar.show(
                message: "DJ request from ${user.name} rejected.",
              );
            },
          ),
          SizedBox(width: isLoadingThis ? AppSpacing.s4 : AppSpacing.s2),
          if (!isLoadingThis)
            _buildCircleActionButton(
              icon: Icons.check,
              backgroundColor: AppColors.success,
              iconColor: Colors.white,
              onTap: () async {
                setState(() {
                  _loadingDjUserIds.add(user.id);
                });
                await roomRef.acceptDjRequest(user.id);
                if (!mounted) return;
                setState(() {
                  _loadingDjUserIds.remove(user.id);
                });
                AppSnackbar.show(
                  message: "${user.name} is now the DJ.",
                );
                AppRouter.instance.pop();
              },
            ),
          if (isLoadingThis)
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeCap: .round,
                strokeWidth: 1.5,
                color: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }

  bool isLoading = false;
  Widget _buildRequestCard(
    BuildContext context,
    RequestItem item,
    RoomProvider roomRef,
  ) {
    final requestedBy = item.requestedBy;
    final avatarColor = AppColors.generateBgColor(requestedBy.name);
    final currentSong = item.song;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairlineDark),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AlbumArtCover(
                seed: currentSong.title,
                size: 56,
                radius: AppRadius.sm,
                child:
                    currentSong.thumbnail != null &&
                        currentSong.thumbnail!.isNotEmpty
                    ? Image.network(
                        currentSong.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentSong.artists?.map((e) => e.name).join(",") ?? ""} · ${_formatDuration(Duration(seconds: currentSong.duration))}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor.bg,
                ),
                child: Center(
                  child: Text(
                    requestedBy.name[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.generateTextColor(requestedBy.name),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: StreamBuilder(
                  stream: Stream.periodic(
                    Duration(seconds: 30),
                    (_) => DateTime.now(),
                  ),
                  builder: (context, asyncSnapshot) {
                    return Text(
                      '@${item.requestedBy.username} · ${timeAgo(item.addedAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                    );
                  },
                ),
              ),
              _buildCircleActionButton(
                icon: Icons.close,
                backgroundColor: AppColors.card,
                iconColor: AppColors.text2,
                onTap: () {
                  roomRef.rejectRequest(
                    item.song.id,
                    item.requestedBy.id,
                    item.addedAt,
                  );
                  AppSnackbar.show(
                    message: "Request from ${item.requestedBy.name} rejected.",
                  );
                },
              ),
              SizedBox(width: isLoading ? AppSpacing.s4 : AppSpacing.s2),
              if (!isLoading)
                _buildCircleActionButton(
                  icon: Icons.check,
                  backgroundColor: AppColors.success,
                  iconColor: Colors.white,
                  onTap: () async {
                    setState(() {
                      isLoading = true;
                    });
                    await roomRef.acceptRequest(
                      item.song.id,
                      item.requestedBy.id,
                      item.addedAt,
                    );
                    setState(() {
                      isLoading = false;
                    });
                    AppSnackbar.show(
                      message: "${item.song.title} added to the queue.",
                    );
                  },
                ),
              if (isLoading)
                SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeCap: .round,
                    strokeWidth: 1.5,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} sec ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      return '${difference.inDays ~/ 30} month${difference.inDays ~/ 30 > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays ~/ 365} year${difference.inDays ~/ 365 > 1 ? 's' : ''} ago';
    }
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  void _showAddToQueueSheet(BuildContext context, RoomProvider roomRef) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddToQueueSheet(
        roomId: widget.roomId,
        addSongToQueue: (song) async {
          if (roomRef.queue.length >= 5) {
            AppSnackbar.show(
              message: "You can only add up to 5 songs to the queue.",
              type: AppSnackType.warning,
            );
            return;
          }

          try {
            await roomRef.addSong(song.id);

            AppSnackbar.show(
              message: 'Added "${song.title}" to the queue.',
              type: AppSnackType.success,
            );
          } catch (e) {
            AppSnackbar.show(
              message: 'Failed to add "${song.title}". Please try again.',
              type: AppSnackType.error,
            );
          }
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AddToQueueSheet extends StatefulWidget {
  final String roomId;
  final Function(SearchSong song) addSongToQueue;
  const _AddToQueueSheet({required this.roomId, required this.addSongToQueue});

  @override
  State<_AddToQueueSheet> createState() => _AddToQueueSheetState();
}

class _AddToQueueSheetState extends State<_AddToQueueSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<SearchSong> _results = [];
  bool _isLoading = false;
  String? _addingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final result = await SearchRepository.instance.search(
      query.trim(),
      filter: SearchFilter.song,
    );
    if (mounted && _searchController.text.trim() == query.trim()) {
      setState(() {
        _results = result?.songs ?? [];
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: AppColors.hairlineLight, width: 1),
            ),
          ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to queue',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton.filled(
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.hairlineDark),
                    borderRadius: AppRadius.smBorderRadius,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: AppSpacing.s3),
                      const Icon(
                        Icons.search,
                        color: AppColors.text3,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              color: AppColors.text3,
                              fontSize: 14,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.close,
                              color: AppColors.text3,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Search for songs to add',
          style: TextStyle(color: AppColors.text3, fontSize: 15),
        ),
      );
    }

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Skeleton(height: 48, width: 48, borderRadius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(height: 14, width: 160, borderRadius: 4),
                    SizedBox(height: 8),
                    Skeleton(height: 12, width: 100, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: AppColors.text3, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final song = _results[index];
        final isAdding = song.id == _addingId;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Row(
            children: [
              AlbumArtCover(
                seed: song.title,
                size: 48,
                radius: AppRadius.xs,
                child: song.thumbnail.isNotEmpty
                    ? Image.network(
                        song.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${song.artists} · ${_formatDuration(song.duration)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                    ),
                  ],
                ),
              ),
              if (isAdding)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      if (_addingId != null) return;
                      setState(() => _addingId = song.id);
                      try {
                        await widget.addSongToQueue(song);
                        if (mounted) {
                          setState(() => _addingId = null);
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(() => _addingId = null);
                        }
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildPlayNextButton(BuildContext context, RoomProvider roomRef) {
  final hasNext = roomRef.queue.isNotEmpty;
  return Material(
    color: hasNext
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.5),
    borderRadius: AppRadius.pillBorderRadius,
    child: InkWell(
      onTap: hasNext
          ? () async {
              try {
                roomRef.playNext();
              } catch (e) {
                if (context.mounted) {
                  AppSnackbar.show(
                    message: "Failed to play next song",
                    type: AppSnackType.error,
                  );
                }
              }
            }
          : () {
              AppSnackbar.show(
                message: "Add more songs to the queue to play next.",
                type: .warning,
              );
            },
      borderRadius: AppRadius.pillBorderRadius,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Play next',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildStopButton(BuildContext context, RoomProvider roomRef) {
  final isPlaying = roomRef.room?.playing == true;
  return Material(
    color: const Color(0xFF2A1215),
    borderRadius: AppRadius.pillBorderRadius,
    child: InkWell(
      onTap: () async {
        try {
          await roomRef.stop();
        } catch (e) {
          if (context.mounted) {
            AppSnackbar.show(
              message: "Failed to stop playback",
              type: AppSnackType.error,
            );
          }
        }
      },
      borderRadius: AppRadius.pillBorderRadius,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(
            color: isPlaying
                ? const Color(0xFF6B2428)
                : const Color(0xFF6B2428).withValues(alpha: 0.5),
          ),
          borderRadius: AppRadius.pillBorderRadius,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stop_rounded,
              color: isPlaying
                  ? AppColors.danger
                  : AppColors.danger.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Stop',
              style: TextStyle(
                color: isPlaying
                    ? AppColors.danger
                    : AppColors.danger.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildLeaveAsDjButton(BuildContext context, RoomProvider roomRef) {
  return Material(
    color: AppColors.surface,
    borderRadius: AppRadius.pillBorderRadius,
    child: InkWell(
      onTap: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) => const _LeaveDjDialog(),
        );
        if (shouldLeave == true && context.mounted) {
          try {
            await roomRef.leaveDj();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (context.mounted) {
              AppSnackbar.show(
                message: "Failed to leave as DJ",
                type: AppSnackType.error,
              );
            }
          }
        }
      },
      borderRadius: AppRadius.pillBorderRadius,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairlineDark),
          borderRadius: AppRadius.pillBorderRadius,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Leave as DJ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LeaveDjDialog extends StatelessWidget {
  const _LeaveDjDialog();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Dialog(
        backgroundColor: AppColors.card.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Step down as DJ?',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You will remain in the room as a listener. Another listener will be automatically assigned as the DJ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text2,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Step down'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.hairlineDark),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
