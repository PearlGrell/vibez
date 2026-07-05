import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/core/utils/share_util.dart';
import 'package:vibez/data/models/queue_item.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class RoomDetailsScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomProvider(roomId));

    return () {
      if (roomState.status == RoomStatus.loading) {
        return _buildGhostLoading(context);
      }
      if (roomState.status == RoomStatus.error) {
        return _buildError(context, ref, roomState.error!);
      }

      final room = roomState.room!;
      final user = ref.watch(userProvider);
      final isMyRoom = user?.myRooms?.any((e) => e.id == room.id) ?? false;
      final hasFollowed =
          user?.joinedRooms?.any((e) => e.id == room.id) ?? false;

      return Scaffold(
        body: _buildBody(
          context,
          ref,
          roomState: roomState,
          isMyRoom: isMyRoom,
        ),
        bottomNavigationBar: _buildBottomBar(
          context,
          ref,
          roomState: roomState,
          isMyRoom: isMyRoom,
          hasFollowed: hasFollowed,
        ),
      );
    }();
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required RoomProvider roomState,
    required bool isMyRoom,
  }) {
    final room = roomState.room!;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(roomProvider(roomId)).refresh(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 56,
              bottom: AppSpacing.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _buildAlbumArt(room)),
                const SizedBox(height: AppSpacing.s6),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s6,
                  ),
                  child: Text(
                    room.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Center(child: _buildTags(context, room)),
                const SizedBox(height: AppSpacing.s4),
                Center(
                  child: room.currentDj != null
                      ? _buildDjChip(context, room)
                      : _buildNoDj(context),
                ),
                const SizedBox(height: AppSpacing.s2),
                Center(
                  child: _buildListeners(
                    context,
                    roomState.participants,
                    roomState.participantsInitials,
                  ),
                ),
                const SizedBox(height: AppSpacing.s7),
                if (room.currentSong != null) ...[
                  _buildNowPlaying(context, room),
                ] else
                  _buildEmptyState(context),
                if (roomState.queue.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s7),
                  _buildUpNext(context, roomState.queue),
                ],
                const SizedBox(height: AppSpacing.s7),
                _buildAboutSection(context, room),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: AppIconButton(
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
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: AppIconButton(
            icon: Icons.ios_share_rounded,
            iconSize: 18,
            onTap: () async {
              ShareUtil(
                shareMode: .room,
                id: room.id,
                title: room.name,
                url: null,
              ).share().then((value) {
                if (!value) {
                  AppSnackbar.show(
                    message: "Failed to share",
                    type: AppSnackType.error,
                  );
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumArt(Room room) {
    return Center(
      child: Stack(
        children: [
          AlbumArtCover(seed: room.name, size: 200),
          if (room.playing)
            Positioned(
              bottom: AppSpacing.s3,
              left: AppSpacing.s4,
              child: EqualizerBars(
                color: Colors.white,
                barCount: 5,
                barSpacing: 4,
                size: 25,
              ),
            ),
          Positioned(
            top: AppSpacing.s2,
            left: AppSpacing.s3,
            child: room.playing
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD14948),
                      borderRadius: AppRadius.pillBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                      vertical: AppSpacing.s1,
                    ),
                    child: const Text(
                      "• LIVE",
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: AppRadius.pillBorderRadius,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                      vertical: AppSpacing.s1,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.text2,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "QUIET",
                          style: TextStyle(
                            color: AppColors.text2,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context, Room room) {
    if (room.tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      alignment: WrapAlignment.center,
      children: room.tags.map((e) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.cardAlt),
            borderRadius: AppRadius.pillBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s1,
          ),
          child: Text(
            e,
            style: const TextStyle(color: AppColors.text2, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDjChip(BuildContext context, Room room) {
    final dj = room.currentDj!;
    final seed = dj.username ?? dj.name;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardAlt),
        borderRadius: AppRadius.pillBorderRadius,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s1 / 2,
        AppSpacing.s1 / 2,
        AppSpacing.s3,
        AppSpacing.s1 / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.generateBgColor(seed).bg,
                ),
                child: Center(
                  child: Text(
                    dj.name[0].toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.generateTextColor(seed),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Text(
            "@${dj.username}",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: AppSpacing.s1),
          Text(
            "• DJ",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDj(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, size: 18, color: AppColors.text2),
        const SizedBox(width: AppSpacing.s2),
        Text(
          "No DJ right now",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
        ),
      ],
    );
  }

  Widget _buildListeners(
    BuildContext context,
    int participants,
    List<String> participantsInitials,
  ) {
    if (participants == 0) {
      return Text(
        "No one here right now",
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: (participantsInitials.length.clamp(0, 5) * 30)
              .clamp(40, 130)
              .toDouble(),
          height: 40,
          child: Stack(
            children: List.generate(participantsInitials.length.clamp(0, 5), (
              index,
            ) {
              final initial = participantsInitials[index];
              return Positioned(
                left: index * 22,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                    color: AppColors.generateBgColor(initial).bg,
                  ),
                  height: 40,
                  width: 40,
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: AppColors.generateTextColor(initial),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        RichText(
          text: TextSpan(
            text: "$participants ",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text,
            ),
            children: [
              TextSpan(
                text: "listening now",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildNowPlaying(BuildContext context, Room room) {
    final song = room.currentSong!;
    final artistName =
        song.artists?.map((e) => e.name).join(', ') ?? 'Unknown Artist';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Now playing",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardAlt),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                AlbumArtCover(
                  seed: song.title,
                  size: 52,
                  radius: AppRadius.xs,
                  child: song.thumbnail != null && song.thumbnail!.isNotEmpty
                      ? Image.network(
                          song.thumbnail!,
                          width: 52,
                          height: 52,
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
                        artistName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (room.playing)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.s2),
                    child: EqualizerBars(
                      color: AppColors.primary,
                      barCount: 4,
                      barWidth: 3,
                      barSpacing: 2,
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpNext(BuildContext context, List<QueueItem> queue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Up next",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s3),
          ...queue.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final artistName =
                item.song.artists?.map((e) => e.name).join(', ') ??
                'Unknown Artist';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  AlbumArtCover(
                    seed: item.song.title,
                    size: 48,
                    radius: AppRadius.xs,
                    child:
                        item.song.thumbnail != null &&
                            item.song.thumbnail!.isNotEmpty
                        ? Image.network(
                            item.song.thumbnail!,
                            width: 48,
                            height: 48,
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
                          item.song.title,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artistName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.text2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, Room room) {
    final aboutText = room.description.isNotEmpty
        ? room.description
        : _generateAboutText(room);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About this room",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            aboutText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
          ),
        ],
      ),
    );
  }

  String _generateAboutText(Room room) {
    final tagStr = room.tags.join(' · ').toLowerCase();
    if (room.currentDj != null) {
      return "A $tagStr room. @${room.currentDj!.username} is currently hosting.";
    }
    return "A $tagStr room. No one's hosting at the moment — be the first to get it going.";
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref, {
    required RoomProvider roomState,
    required bool isMyRoom,
    required bool hasFollowed,
  }) {
    final room = roomState.room!;
    final notifier = ref.read(roomProvider(roomId));

    String label;
    if (roomState.isInRoom) {
      label = "Listening";
    } else if (room.playing || roomState.participants > 0) {
      label = "Join · ${roomState.participants} listening";
    } else {
      label = "Start the vibe";
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          children: [
            if (!isMyRoom) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    try {
                      await notifier.toggleFollow();
                    } catch (_) {
                      AppSnackbar.show(
                        message: "Failed to update follow",
                        type: AppSnackType.error,
                      );
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.cardAlt),
                    ),
                    child: Icon(
                      hasFollowed ? Icons.check : Icons.add,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
            ],
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AppRadius.pillBorderRadius,
                  onTap: () async {
                    if (roomState.isInRoom) {
                      await AppRouter.instance.push<bool>(
                        '/room/$roomId/player',
                      );
                      return;
                    }
                    try {
                      await notifier.joinRoom();
                      AppSnackbar.show(
                        message: "Joined the room",
                        type: AppSnackType.success,
                      );
                      await AppRouter.instance.push<bool>(
                        '/room/$roomId/player',
                      );
                    } catch (_) {
                      AppSnackbar.show(
                        message: "Failed to join room",
                        type: AppSnackType.error,
                      );
                    }
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.pillBorderRadius,
                      boxShadow: AppShadows.shGlowMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.headphones_outlined, size: 20),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Scaffold(
      appBar: AppBar(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.text2),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Could not load room',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              child: Text(
                '$error',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextButton(
              onPressed: () => ref.read(roomProvider(roomId)).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostLoading(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 56),
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Container(
                height: 40,
                width: 250,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pillBorderRadius,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pillBorderRadius,
                ),
              ),
              const SizedBox(height: AppSpacing.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      height: 30,
                      width: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.pillBorderRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Container(
                height: 48,
                width: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pillBorderRadius,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s4,
          0,
          AppSpacing.s4,
          kBottomNavigationBarHeight,
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.pillBorderRadius,
          ),
        ),
      ),
    );
  }
}
