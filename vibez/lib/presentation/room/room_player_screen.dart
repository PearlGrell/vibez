import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/user.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/data/provider/room_playback_provider.dart';
import 'package:vibez/data/services/player_audio_service.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class RoomPlayerScreen extends ConsumerWidget {
  final String roomId;
  const RoomPlayerScreen({super.key, required this.roomId});

  Future<void> _confirmLeave(
    BuildContext context,
    RoomProvider roomProvider,
    User? user,
  ) async {
    if (user != null) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) =>
            _LeaveRoomDialog(isDj: roomProvider.room?.currentDj?.id == user.id),
      );
      if (shouldLeave == true && context.mounted) {
        roomProvider.leaveRoom();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(roomPlaybackProvider);
    final roomRef = ref.watch(roomProvider(roomId));
    final userRef = ref.watch(userProvider);
    final room = roomRef.room;
    final isDj = roomRef.room?.currentDj?.id == userRef?.id;

    if (room == null) {
      roomRef.leaveRoom();
      Navigator.of(context).pop();
      return SizedBox.shrink();
    }

    final song = room.currentSong;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLeave(context, roomRef, userRef);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, roomRef, userRef, isDj),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: AppSpacing.s4),
                    Center(
                      child: room.currentDj != null
                          ? _buildDjChip(context, room, isDj, roomId)
                          : _buildNoDj(context),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _buildAlbumArt(room),
                    const SizedBox(height: AppSpacing.s4),
                    Center(
                      child: Text(
                        song?.title ?? "Nothing is playing right now.",
                        style: Theme.of(context).textTheme.headlineLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Center(
                      child: Text(
                        song?.artists?.map((e) => e.name).join(", ") ??
                            (isDj
                                ? "Queue up some songs to get the music started"
                                : "Request a song from the DJ to get things going"),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (song != null) ...[
                      const SizedBox(height: AppSpacing.s6 * 0.85),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s4,
                        ),
                        child: _buildProgressBar(roomRef, song),
                      ),
                    ],
                  ],
                ),
              ),
              _buildBottomBar(context, isDj),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    RoomProvider roomRef,
    User? userRef,
    bool isDj,
  ) {
    return AppBar(
      leading: AppIconButton(
        icon: Icons.chevron_left,
        onTap: () => _confirmLeave(context, roomRef, userRef),
      ),
      actions: [
        AppIconButton(
          icon: Icons.ios_share_rounded,
          iconSize: 18,
          onTap: () {},
        ),
      ],
      title: Column(
        crossAxisAlignment: .center,
        children: [
          Row(
            mainAxisAlignment: .center,
            children: [
              if (!(roomRef.room?.playing ?? false)) ...[
                const Icon(Icons.circle, size: 8, color: AppColors.danger),
                const SizedBox(width: 6),
              ],
              Text(
                roomRef.room?.name ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: .center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: .center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.text2,
              ),
              const SizedBox(width: 4),
              Text(
                "${roomRef.participants} listening",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildProgressBar(RoomProvider roomRef, Song currentSong) {
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  final durationMs = currentSong.duration * 1000;
  return StreamBuilder<Duration>(
    stream: PlayerAudioService.roomHandler.positionStream,
    builder: (context, snapshot) {
      final position = snapshot.data ?? Duration.zero;
      final elapsedMs = position.inMilliseconds.clamp(0, durationMs);
      final progress = durationMs == 0 ? 0.0 : elapsedMs / durationMs;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.card,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(
                  Duration(milliseconds: elapsedMs),
                ),
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
              Text(
                formatDuration(Duration(seconds: currentSong.duration)),
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Widget _buildBottomBar(BuildContext context, bool isDj) {
  return Container(
    height: kBottomNavigationBarHeight * 1.2,
    padding: .symmetric(horizontal: AppSpacing.s3),
    margin: EdgeInsets.fromLTRB(AppSpacing.s3, 0, AppSpacing.s3, AppSpacing.s3),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.5),
      border: Border.all(color: AppColors.hairlineDark),
      borderRadius: AppRadius.pillBorderRadius,
    ),
    child: Row(
      spacing: AppSpacing.s2,
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: .only(left: AppSpacing.s3),
              hint: Text("Say something..."),
            ),
            maxLines: 1,
          ),
        ),
        if (!isDj)
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: AppSpacing.s2 * 1.2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.card),
                borderRadius: AppRadius.pillBorderRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.music_note_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Request",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: AppShadows.shGlowMd,
            shape: .circle,
          ),
          child: IconButton.filled(
            onPressed: () {},
            icon: Icon(Icons.send_rounded),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAlbumArt(Room room) {
  return Center(
    child: Stack(
      children: [
        AlbumArtCover(seed: room.name, size: 250),
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
      ],
    ),
  );
}

Widget _buildDjChip(BuildContext context, Room room, bool isDj, String roomId) {
  final dj = room.currentDj!;
  final seed = dj.username ?? dj.name;
  return Row(
    mainAxisSize: .min,
    children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.cardAlt),
          borderRadius: AppRadius.pillBorderRadius,
        ),
        padding: EdgeInsets.fromLTRB(
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
                  height: 32,
                  width: 32,
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
              "@${isDj ? "you" : dj.username}",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isDj ? FontWeight.normal : FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            if (!isDj) ...[
              const SizedBox(width: AppSpacing.s1),
              Text(
                "• DJ",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
              ),
            ],
          ],
        ),
      ),

      if (isDj) ...[
        const SizedBox(width: AppSpacing.s1),
        AppIconButton(
          icon: Icons.graphic_eq_rounded,
          iconSize: 18,
          onTap: () {
            AppRouter.instance.push('/room/$roomId/dj');
          },
        ),
      ],
    ],
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

class _LeaveRoomDialog extends StatelessWidget {
  final bool isDj;
  const _LeaveRoomDialog({required this.isDj});

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
                  Icons.headphones_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Leave this room?',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You'll stop listening with the room and "
                'leave the live session. You can rejoin anytime. ${isDj ? "\nNOTE: You will be removed as a DJ." : ""}',
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
                  child: const Text('Leave room'),
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
                  child: const Text('Stay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
