import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/queue_item.dart';
import 'package:vibez/data/models/request_item.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final roomRef = ref.watch(roomProvider(widget.roomId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, roomRef),
            const SizedBox(height: AppSpacing.s4),
            _buildTabBar(context),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: _selectedTab == 0
                  ? _buildBoothTab(context, roomRef)
                  : _buildRequestsTab(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──

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

  // ── Tab Bar ──

  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(child: _buildTab('Booth', 0)),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: _buildTab('Requests · ${0}', 1), // TODO: add requests number
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

  // ── Booth Tab ──

  Widget _buildBoothTab(BuildContext context, RoomProvider roomRef) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNowPlaying(context, roomRef),
          const SizedBox(height: AppSpacing.s7),
          _buildUpNextHeader(context, roomRef),
          const SizedBox(height: AppSpacing.s3),
          ...roomRef.queue.asMap().entries.map(
            (entry) =>
                _buildQueueItem(context, entry.key, entry.value, () async {
                  await roomRef.removeSong(entry.value.id);
                }),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  // ── Now Playing ──

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
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 0.5, // TODO: Add progress
              backgroundColor: AppColors.card,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "0:00", // TODO: Add elapsed
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
              Text(
                _formatDuration(Duration(seconds: currentSong.duration)),
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconButton(icon: Icons.skip_previous_rounded, onTap: () {}),
              const SizedBox(width: AppSpacing.s5),
              GestureDetector(
                onTap: () async {
                  if (roomRef.room?.playing == true) {
                  } else {
                  }
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.shGlowMd,
                  ),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      roomRef.room?.playing == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.text,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s5),
              AppIconButton(icon: Icons.skip_next_rounded, onTap: () {}),
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

  // ── Up Next Header ──

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

  // ── Queue Item ──

  Widget _buildQueueItem(
    BuildContext context,
    int index,
    QueueItem item,
    Function() onRemove,
  ) {
    final isDj = item.addedBy.id == ref.watch(userProvider)?.id;
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
                            : 'req @${item.addedBy.name}',
                        style: const TextStyle(color: AppColors.danger),
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
                type: .success,
              );
            },
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

  // ── Requests Tab ──

  Widget _buildRequestsTab(BuildContext context) {
    // TODO: Wire up to actual requests list from roomRef
    final requests = <RequestItem>[];

    if (requests.isEmpty) {
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
                  "When listeners request a track,\nit'll show up here for you to accept.",
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
          Text(
            'Listeners are requesting tracks. Accept to drop them into the queue.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
          ),
          const SizedBox(height: AppSpacing.s4),
          ...requests.map((r) => _buildRequestCard(context, r)),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestItem item) {
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
                child: Text(
                  '@${item.requestedBy} · ${item.addedAt}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.text2),
                ),
              ),
              _buildCircleActionButton(
                icon: Icons.close,
                backgroundColor: AppColors.card,
                iconColor: AppColors.text2,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.s2),
              _buildCircleActionButton(
                icon: Icons.check,
                backgroundColor: AppColors.success,
                iconColor: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
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

  // ── Add to Queue Bottom Sheet ──

  void _showAddToQueueSheet(BuildContext context, RoomProvider roomRef) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddToQueueSheet(
        roomId: widget.roomId,
        addSongToQueue: (id) async {
          await roomRef.addSong(id);
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

// ── Add to Queue Sheet ──

class _AddToQueueSheet extends StatefulWidget {
  final String roomId;
  final Function(String id) addSongToQueue;
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
                        await widget.addSongToQueue(song.id);
                        if (mounted) {
                          setState(() => _addingId = null);
                          AppSnackbar.show(
                            message: 'Added ${song.title}',
                            type: .success,
                          );
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
