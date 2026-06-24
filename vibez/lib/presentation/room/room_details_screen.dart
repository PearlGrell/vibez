import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';
import 'package:vibez/data/services/room_socket_service.dart';

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen> {
  late Future<({Room room, int participants})> _roomDetailsFuture;
  late final Stream<({Room room, int participants})> _roomStateStream;

  @override
  void initState() {
    super.initState();
    final socketService = ref.read(roomSocketServiceProvider);
    _roomDetailsFuture = socketService.getRoomDetails(widget.roomId);
    _roomStateStream = socketService.roomStateUpdates;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Room room, int participants})>(
      future: _roomDetailsFuture,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return _buildGhostLoading(context);
        }

        if (asyncSnapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(context),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s6,
                    ),
                    child: Text(
                      '${asyncSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _roomDetailsFuture = ref
                            .read(roomSocketServiceProvider)
                            .getRoomDetails(widget.roomId);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final initialData = asyncSnapshot.data;
        if (initialData == null) {
          return const Scaffold(body: Center(child: Text('Room not found')));
        }

        return StreamBuilder<({Room room, int participants})>(
          stream: _roomStateStream,
          builder: (context, streamSnapshot) {
            final room = streamSnapshot.data?.room ?? initialData.room;
            final participants =
                streamSnapshot.data?.participants ?? initialData.participants;

            return Scaffold(
              appBar: _buildAppBar(context),
              body: _buildBody(context, room, participants),
              bottomNavigationBar: _buildBottomBar(context, room),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
        AppIconButton(
          icon: Icons.ios_share_outlined,
          iconSize: 18,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, Room room, int participants) {
    return Center(
      child: Column(
        children: [
          Stack(
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
                child: (room.playing)
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
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.s1),
                        child: Icon(
                          Icons.podcasts_outlined,
                          size: 16,
                          color: AppColors.text2,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            room.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: AppSpacing.s5),
          Wrap(
            direction: Axis.horizontal,
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
          ),
          const SizedBox(height: AppSpacing.s4),
          if (room.currentDj != null) ...[
            Container(
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
                          color: AppColors.generateBgColor(
                            room.currentDj!.username!,
                          ).bg,
                        ),
                        child: Center(
                          child: Text(
                            room.currentDj!.name[0].toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.generateTextColor(
                                    room.currentDj!.username!,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    "@${room.currentDj!.username}",
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
            ),
            const SizedBox(height: AppSpacing.s6),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (participants == 0) ...[
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
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.text2),
                ),
              ] else ...[
                SizedBox(
                  width: (participants.clamp(0, 5) * 30)
                      .clamp(40, 130)
                      .toDouble(),
                  height: 40,
                  child: Stack(
                    children: List.generate(
                      participants <= 5 ? participants : 5,
                      (index) {
                        final randomChar = String.fromCharCode(
                          65 + Random().nextInt(26),
                        );
                        final seed = '$randomChar${Random().nextInt(1000)}';
                        return Positioned(
                          left: index * 22,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                              color: AppColors.generateBgColor(seed).bg,
                            ),
                            height: 40,
                            width: 40,
                            child: Center(
                              child: Text(
                                randomChar,
                                style: TextStyle(
                                  color: AppColors.generateTextColor(seed),
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
                const SizedBox(width: AppSpacing.s3),
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
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Room room) {
    return Padding(
      padding: .fromLTRB(
        AppSpacing.s4,
        0,
        AppSpacing.s4,
        kBottomNavigationBarHeight,
      ),
      child: Row(
        spacing: AppSpacing.s6,
        children: [
          if (ref.watch(myRoomsProvider).value?.any((e) => e.id == room.id) ==
              false)
            Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(userProvider);
                final hasJoined =
                    user?.joinedRooms?.any(
                      (element) => element.id == room.id,
                    ) ??
                    false;
                return GestureDetector(
                  onTap: () {
                    if (hasJoined) {
                      ref.read(userProvider.notifier).unfollowRoom(room.id);
                    } else {
                      ref.read(userProvider.notifier).followRoom(room);
                    }
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.cardAlt),
                      borderRadius: AppRadius.pillBorderRadius,
                    ),
                    child: Row(
                      spacing: AppSpacing.s2,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(hasJoined ? Icons.check : Icons.add),
                        Text(
                          hasJoined ? "Following" : "Follow",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (room.currentDj == null)
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardAlt),
                borderRadius: AppRadius.pillBorderRadius,
              ),
              child: Row(
                spacing: AppSpacing.s2,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speaker_group_rounded),
                  Text(
                    "Join as DJ",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: AppShadows.shGlowMd,
                borderRadius: AppRadius.pillBorderRadius,
              ),
              child: Row(
                spacing: AppSpacing.s2,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.headphones_outlined),
                  Text(
                    "Join Room",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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

  Widget _buildGhostLoading(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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
        child: Row(
          spacing: AppSpacing.s6,
          children: [
            Container(
              height: 56,
              width: 150,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.pillBorderRadius,
              ),
            ),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.pillBorderRadius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
