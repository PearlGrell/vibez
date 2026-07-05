import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/core/utils/share_util.dart';
import 'package:vibez/data/models/lyrics.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/user.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/data/provider/room_playback_provider.dart';
import 'package:vibez/data/repositories/search_repository.dart';
import 'package:vibez/data/repositories/song_repository.dart';
import 'package:vibez/data/services/player_audio_service.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/presentation/common/skeleton.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class RoomPlayerScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomPlayerScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomPlayerScreen> createState() => _RoomPlayerScreenState();
}

class _RoomPlayerScreenState extends ConsumerState<RoomPlayerScreen> {
  StreamSubscription? _songRequestAlertSub;
  StreamSubscription? _djRequestAlertSub;

  Timer? _upNextTimer;
  String? _upNextTimerSongId;
  Song? _upNextSong;

  Lyrics? _currentLyrics;
  String? _lyricsForSongId;
  ProviderSubscription<RoomProvider>? _roomSub;

  Future<void> _fetchLyrics(String songId) async {
    _lyricsForSongId = songId;
    try {
      final lyrics = await SongRepository.instance.getLyrics(songId);
      if (mounted && _lyricsForSongId == songId) {
        setState(() => _currentLyrics = lyrics);
      }
    } catch (_) {}
  }

  void _clearLyrics() {
    _currentLyrics = null;
    _lyricsForSongId = null;
  }

  @override
  void initState() {
    super.initState();
    final roomRef = ref.read(roomProvider(widget.roomId));

    _roomSub = ref.listenManual(roomProvider(widget.roomId), (prev, next) {
      final prevSongId = prev?.room?.currentSong?.id;
      final nextSongId = next.room?.currentSong?.id;
      final stopped =
          (prev?.room?.playing ?? false) && !(next.room?.playing ?? false);
      if (prevSongId != nextSongId || stopped) {
        if (mounted) setState(_clearLyrics);
        if (nextSongId != null && !stopped) _fetchLyrics(nextSongId);
      }
    }, fireImmediately: true);

    _songRequestAlertSub = roomRef.onSongRequested.listen((item) {
      final userRef = ref.read(userProvider);
      final isDj = roomRef.room?.currentDj?.id == userRef?.id;
      if (!isDj) return;
      AppSnackbar.show(
        message: "${item.requestedBy.name} requested \"${item.song.title}\"",
      );
    });

    _djRequestAlertSub = roomRef.onDjRequested.listen((user) {
      final userRef = ref.read(userProvider);
      final isDj = roomRef.room?.currentDj?.id == userRef?.id;
      if (!isDj) return;
      AppSnackbar.show(message: "${user.name} wants to be the DJ");
    });
  }

  void _syncUpNextTimer(RoomProvider roomRef, Song currentSong) {
    if (_upNextTimerSongId == currentSong.id) return;
    _upNextTimer?.cancel();
    _upNextTimerSongId = currentSong.id;
    _upNextSong = null;

    final leadSeconds = currentSong.duration - 5;
    if (leadSeconds <= 0) return;

    _upNextTimer = Timer(Duration(seconds: leadSeconds), () {
      if (!mounted) return;
      if (ref.read(roomProvider(widget.roomId)).room?.currentSong?.id !=
          currentSong.id) {
        return;
      }
      final next = roomRef.queue.isNotEmpty ? roomRef.queue.first.song : null;
      if (next == null) return;
      setState(() => _upNextSong = next);
    });
  }

  @override
  void dispose() {
    _roomSub?.close();
    _songRequestAlertSub?.cancel();
    _djRequestAlertSub?.cancel();
    _upNextTimer?.cancel();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    ref.watch(roomPlaybackProvider);
    final roomRef = ref.watch(roomProvider(widget.roomId));
    final userRef = ref.watch(userProvider);
    final room = roomRef.room;
    final isDj = roomRef.room?.currentDj?.id == userRef?.id;

    if (room == null) {
      roomRef.leaveRoom();
      Navigator.of(context).pop();
      return SizedBox.shrink();
    }

    final song = room.currentSong;

    if (song != null) {
      _syncUpNextTimer(roomRef, song);
    } else {
      _upNextTimer?.cancel();
      _upNextTimerSongId = null;
      _upNextSong = null;
    }

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
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: AppSpacing.s4),
                        Center(
                          child: room.currentDj != null
                              ? _buildDjChip(
                                  context,
                                  room,
                                  isDj,
                                  widget.roomId,
                                  roomRef,
                                )
                              : _buildNoDj(context),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        _FlippableAlbumCard(room: room, lyrics: _currentLyrics),
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
                            textAlign: .center,
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
                  _buildBottomBar(context, isDj, roomRef),
                ],
              ),
              if (_upNextSong != null && song != null)
                _buildUpNextOverlay(context, _upNextSong!, song),
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
          onTap: () async {
            final room = roomRef.room;
            if (room != null) {
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
            }
          },
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
  final duration = currentSong.duration;

  return StreamBuilder<Duration>(
    stream: PlayerAudioService.roomHandler.positionStream,
    builder: (context, snapshot) {
      final position = snapshot.data ?? Duration.zero;
      final elapsed = position.inSeconds.clamp(0, duration);
      final progress = duration == 0 ? 0.0 : elapsed / duration;

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
                _formatDuration(Duration(seconds: elapsed)),
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
              Text(
                _formatDuration(Duration(seconds: duration)),
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    },
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

Widget _buildUpNextOverlay(
  BuildContext context,
  Song upNextSong,
  Song currentSong,
) {
  return Positioned(
    top: AppSpacing.s4,
    right: AppSpacing.s4,
    child: AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1,
        child: _buildUpNextCard(context, upNextSong, currentSong),
      ),
    ),
  );
}

Widget _buildUpNextCard(
  BuildContext context,
  Song upNextSong,
  Song currentSong,
) {
  return Container(
    constraints: const BoxConstraints(maxWidth: 220),
    padding: const EdgeInsets.all(AppSpacing.s2),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.95),
      border: Border.all(color: AppColors.hairlineDark),
      borderRadius: AppRadius.mdBorderRadius,
      boxShadow: AppShadows.shGlowMd,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AlbumArtCover(
          seed: upNextSong.title,
          size: 40,
          radius: AppRadius.xs,
          child:
              upNextSong.thumbnail != null && upNextSong.thumbnail!.isNotEmpty
              ? Image.network(
                  upNextSong.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.s2),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'UP NEXT',
                style: TextStyle(
                  color: AppColors.text2,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                upNextSong.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StreamBuilder<Duration>(
                stream: PlayerAudioService.roomHandler.positionStream,
                builder: (context, snapshot) {
                  final duration = currentSong.duration;
                  final elapsed = (snapshot.data?.inSeconds ?? 0).clamp(
                    0,
                    duration,
                  );
                  final remaining = (duration - elapsed).clamp(0, duration);
                  return Text(
                    'Playing in ${remaining}s',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBottomBar(BuildContext context, bool isDj, RoomProvider roomRef) {
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
            onTap: () {
              _showRequestBottomsheet(context, roomRef);
            },
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

class _FlippableAlbumCard extends StatefulWidget {
  final Room room;
  final Lyrics? lyrics;

  const _FlippableAlbumCard({required this.room, required this.lyrics});

  @override
  State<_FlippableAlbumCard> createState() => _FlippableAlbumCardState();
}

class _FlippableAlbumCardState extends State<_FlippableAlbumCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotationAnim;
  late final Animation<double> _widthFractionAnim;
  bool _showingLyrics = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotationAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    _widthFractionAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_FlippableAlbumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final songChanged =
        oldWidget.room.currentSong?.id != widget.room.currentSong?.id;
    final lyricsCleared = oldWidget.lyrics != null && widget.lyrics == null;
    final stopped = oldWidget.room.playing && !widget.room.playing;
    if ((songChanged || lyricsCleared || stopped) && _showingLyrics) {
      _ctrl.reverse();
      setState(() => _showingLyrics = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showingLyrics) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _showingLyrics = !_showingLyrics);
  }

  @override
  Widget build(BuildContext context) {
    final hasLyrics = widget.lyrics != null && widget.lyrics!.lyrics.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;

        return Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final angle = _rotationAnim.value * math.pi;
              final isFront = angle <= math.pi / 2;
              const maxLyricsWidth = 320.0;
              final currentWidth =
                  200.0 +
                  (math.min(fullWidth, maxLyricsWidth) - 200.0) *
                      _widthFractionAnim.value;

              return SizedBox(
                width: currentWidth,
                height: 200,
                child: Transform(
                  alignment: Alignment.center,
                  transform: isFront
                      ? (Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle))
                      : (Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle - math.pi)),
                  child: isFront ? _buildFront(hasLyrics) : _buildBack(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFront(bool hasLyrics) {
    final song = widget.room.currentSong;
    final hasCover = song?.thumbnail != null && song!.thumbnail!.isNotEmpty;

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          children: [
            AlbumArtCover(
              seed: song?.title ?? widget.room.name,
              size: 200,
              child: hasCover
                  ? Image.network(
                      song.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    )
                  : null,
            ),
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
            if (hasLyrics)
              Positioned(
                bottom: AppSpacing.s3,
                right: AppSpacing.s3,
                child: GestureDetector(
                  onTap: _flip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.hairlineDark),
                    ),
                    child: const Text(
                      'Lyrics',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
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

  Widget _buildBack() {
    final lyrics = widget.lyrics;
    if (lyrics == null || lyrics.lyrics.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairlineDark),
          ),
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: Center(
            child: StreamBuilder<Duration>(
              stream: PlayerAudioService.roomHandler.positionStream,
              builder: (context, snapshot) {
                final posMs = snapshot.data?.inMilliseconds ?? 0;
                int currentIndex = 0;

                if (lyrics.hasTimestamps) {
                  for (int i = lyrics.lyrics.length - 1; i >= 0; i--) {
                    if (posMs >= lyrics.lyrics[i].startTime) {
                      currentIndex = i;
                      break;
                    }
                  }
                } else {
                  final songDurationMs =
                      (widget.room.currentSong?.duration ?? 0) * 1000;
                  final count = lyrics.lyrics.length;
                  currentIndex = songDurationMs > 0
                      ? ((posMs / songDurationMs) * count).floor().clamp(
                          0,
                          count - 1,
                        )
                      : 0;
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    lyrics.lyrics[currentIndex].text,
                    key: ValueKey(currentIndex),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.s2,
          left: AppSpacing.s3,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
              vertical: AppSpacing.s1,
            ),
            child: const Text(
              'LYRICS',
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.s2,
          right: AppSpacing.s2,
          child: GestureDetector(
            onTap: _flip,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.text2,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

void _showRequestBottomsheet(BuildContext context, RoomProvider ref) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return _RequestSheet(
        roomId: ref.roomId,
        addSongToQueue: (song) async {
          await ref.requestSong(song.id);
          AppSnackbar.show(message: "Requested ${song.title} to  DJ");
        },
      );
    },
  );
}

Widget _buildDjChip(
  BuildContext context,
  Room room,
  bool isDj,
  String roomId,
  RoomProvider roomRef,
) {
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
      if (!isDj) ...[
        const SizedBox(width: AppSpacing.s1),
        AppIconButton(
          icon: Icons.back_hand_outlined,
          iconSize: 18,
          onLongPress: () {
            Fluttertoast.showToast(msg: "Request to be  DJ");
          },
          onTap: () async {
            await roomRef.requestDj();
            AppSnackbar.show(message: "Asked to be DJ");
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

class _RequestSheet extends StatefulWidget {
  final String roomId;
  final Function(SearchSong song) addSongToQueue;
  const _RequestSheet({required this.roomId, required this.addSongToQueue});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
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
                        'Request Song',
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
          'Search for songs to request',
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
