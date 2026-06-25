import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
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

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ref.read(roomProvider(roomId)).leaveRoom();
      },
      child: () {
        if (roomState.status == RoomStatus.loading) {
          return _buildGhostLoading(context, ref);
        }
        if (roomState.status == RoomStatus.error) {
          return _buildError(context, ref, roomState.error!);
        }

        final room = roomState.room!;
        final user = ref.watch(userProvider);
        final hasJoined =
            user?.joinedRooms?.any((e) => e.id == room.id) ?? false;
        final isDj = room.currentDj?.id == user?.id;
        final isMyRoom =
            user?.myRooms?.any((e) => e.id == room.id) ?? false;

        return Scaffold(
          appBar: _buildAppBar(context, ref, room),
          body: _buildBody(
            context,
            ref,
            roomState: roomState,
            hasJoined: hasJoined,
            isDj: isDj,
            isMyRoom: isMyRoom,
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            ref,
            roomState: roomState,
            isDj: isDj,
          ),
        );
      }(),
    );
  }

  // ── App Bar ──

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref, [
    Room? room,
  ]) {
    return AppBar(
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
      actions: [
        if (room != null && room.createdById == ref.watch(userProvider)?.id)
          AppIconButton(
            icon: Icons.edit_rounded,
            onTap: () async {
              final result = await AppRouter.instance.push(
                RouteLocation.roomAdd,
                extra: room,
              );
              if (result == true) {
                ref.read(roomProvider(roomId)).refresh();
              }
            },
          ),
        AppIconButton(
          icon: Icons.ios_share_outlined,
          iconSize: 18,
          onTap: () {},
        ),
      ],
    );
  }

  // ── Body ──

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required RoomProvider roomState,
    required bool hasJoined,
    required bool isDj,
    required bool isMyRoom,
  }) {
    final room = roomState.room!;

    return RefreshIndicator(
      onRefresh: () => ref.read(roomProvider(roomId)).refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  _buildAlbumArt(room),
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  if (room.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      room.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s5),
                  _buildTags(context, room),
                  const SizedBox(height: AppSpacing.s4),
                  if (room.currentDj != null) ...[
                    _buildDjChip(context, room),
                    const SizedBox(height: AppSpacing.s4),
                  ],
                  _buildListeners(
                    context,
                    roomState.participants,
                    roomState.participantsInitials,
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  _buildInlineActions(
                    context,
                    ref,
                    roomState: roomState,
                    hasJoined: hasJoined,
                    isMyRoom: isMyRoom,
                  ),
                ],
              ),
            ),
            if (room.currentSong != null) ...[
              const SizedBox(height: AppSpacing.s7),
              _buildNowPlaying(context, room),
            ],
          ],
        ),
      ),
    );
  }

  // ── Album Art ──

  Widget _buildAlbumArt(Room room) {
    return Stack(
      children: [
        AlbumArtCover(seed: room.name, size: 200),
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
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.s1),
                  child: const Icon(
                    Icons.podcasts_outlined,
                    size: 16,
                    color: AppColors.text2,
                  ),
                ),
        ),
      ],
    );
  }

  // ── Tags ──

  Widget _buildTags(BuildContext context, Room room) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
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

  // ── DJ Chip ──

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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Listeners ──

  Widget _buildListeners(
    BuildContext context,
    int participants,
    List<String> participantsInitials,
  ) {
    if (participants == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
              color: AppColors.generateBgColor("No User").bg,
            ),
            height: 40,
            width: 40,
            child: Center(
              child: Icon(
                Icons.person,
                color: AppColors.generateTextColor("No User"),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Text(
            "No listeners yet.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.text2,
            ),
          ),
        ],
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
            children: List.generate(
              participantsInitials.length.clamp(0, 5),
              (index) {
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
              },
            ),
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

  // ── Inline Actions ──

  Widget _buildInlineActions(
    BuildContext context,
    WidgetRef ref, {
    required RoomProvider roomState,
    required bool hasJoined,
    required bool isMyRoom,
  }) {
    final notifier = ref.read(roomProvider(roomId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _pillButton(
              context,
              icon: isMyRoom || hasJoined ? Icons.check : Icons.add,
              label: isMyRoom || hasJoined ? "Following" : "Follow",
              onTap: isMyRoom
                  ? null
                  : () async {
                      try {
                        await notifier.toggleFollow();
                      } catch (_) {
                        AppSnackbar.show(
                          message: "Failed to update follow",
                          type: .error,
                        );
                      }
                    },
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            flex: 3,
            child: _pillButton(
              context,
              icon: Icons.headphones_outlined,
              label: roomState.isInRoom ? "Listening" : "Join room",
              isPrimary: true,
              onTap: roomState.isInRoom
                  ? null
                  : () async {
                      try {
                        await notifier.joinRoom();
                        AppSnackbar.show(
                          message: "Joined the room",
                          type: .success,
                        );
                      } catch (_) {
                        AppSnackbar.show(
                          message: "Failed to join room",
                          type: .error,
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillBorderRadius,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.surface,
            border: isPrimary ? null : Border.all(color: AppColors.cardAlt),
            borderRadius: AppRadius.pillBorderRadius,
            boxShadow: isPrimary ? AppShadows.shGlowMd : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.s2),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Now Playing ──

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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.text2),
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

  // ── Bottom Bar ──

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref, {
    required RoomProvider roomState,
    required bool isDj,
  }) {
    final notifier = ref.read(roomProvider(roomId));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          children: [
            if (roomState.isInRoom && isDj) ...[
              Expanded(
                child: _bottomBarButton(
                  context,
                  icon: Icons.speaker_group_rounded,
                  label: "Leave as DJ",
                  onTap: () async {
                    try {
                      await notifier.leaveDj();
                      AppSnackbar.show(
                        message: "Left as DJ",
                        type: .success,
                      );
                    } catch (_) {
                      AppSnackbar.show(
                        message: "Failed to leave as DJ",
                        type: .error,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
            ],
            Expanded(
              child: _bottomBarButton(
                context,
                icon: roomState.isInRoom
                    ? Icons.logout_rounded
                    : Icons.headphones_outlined,
                label: roomState.isInRoom ? "Leave" : "Join",
                suffix: " · ${roomState.participants} listening",
                isPrimary: true,
                onTap: () async {
                  try {
                    if (roomState.isInRoom) {
                      await notifier.leaveRoom();
                      AppSnackbar.show(
                        message: "Left the room",
                        type: .success,
                      );
                    } else {
                      await notifier.joinRoom();
                      AppSnackbar.show(
                        message: "Joined the room",
                        type: .success,
                      );
                    }
                  } catch (_) {
                    AppSnackbar.show(
                      message: roomState.isInRoom
                          ? "Failed to leave room"
                          : "Failed to join room",
                      type: .error,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? suffix,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillBorderRadius,
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.surface,
            border: isPrimary ? null : Border.all(color: AppColors.cardAlt),
            borderRadius: AppRadius.pillBorderRadius,
            boxShadow: isPrimary ? AppShadows.shGlowMd : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.s2),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error ──

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.text2),
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

  // ── Ghost Loading ──

  Widget _buildGhostLoading(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: Center(
        child: Column(
          children: [
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
