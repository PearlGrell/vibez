import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/shadows.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class _QueueItem {
  final String title;
  final String artist;
  final String requestedBy;
  final String artSeed;

  const _QueueItem({
    required this.title,
    required this.artist,
    required this.requestedBy,
    required this.artSeed,
  });
}

class _RequestItem {
  final String title;
  final String artist;
  final String duration;
  final String requestedBy;
  final String timeAgo;
  final String artSeed;

  const _RequestItem({
    required this.title,
    required this.artist,
    required this.duration,
    required this.requestedBy,
    required this.timeAgo,
    required this.artSeed,
  });
}

class _SearchSongItem {
  final String title;
  final String artist;
  final String duration;
  final String artSeed;

  const _SearchSongItem({
    required this.title,
    required this.artist,
    required this.duration,
    required this.artSeed,
  });
}

class DjControlScreen extends StatefulWidget {
  final String roomId;
  const DjControlScreen({super.key, required this.roomId});

  @override
  State<DjControlScreen> createState() => _DjControlScreenState();
}

class _DjControlScreenState extends State<DjControlScreen> {
  int _selectedTab = 0;
  bool _isPlaying = true;
  final double _progress = 0.59;

  static const _currentSong = (
    title: 'Von Dutch',
    artist: 'Charli xcx',
    elapsed: '1:41',
    total: '2:48',
    artSeed: 'Von Dutch',
  );

  static const _queue = [
    _QueueItem(
      title: 'Bad Decisions',
      artist: 'PinkPantheress',
      requestedBy: 'mira',
      artSeed: 'Bad Decisions',
    ),
    _QueueItem(
      title: 'Simulation',
      artist: 'Skee Mask',
      requestedBy: 'dj',
      artSeed: 'Simulation',
    ),
    _QueueItem(
      title: 'Voyager',
      artist: 'Daft Punk',
      requestedBy: 'kaze',
      artSeed: 'Voyager',
    ),
    _QueueItem(
      title: 'Smalltown Boy',
      artist: 'Jamie xx edit',
      requestedBy: 'lola',
      artSeed: 'Smalltown Boy',
    ),
  ];

  static const _requests = [
    _RequestItem(
      title: 'Nights',
      artist: 'Frank Ocean',
      duration: '5:07',
      requestedBy: 'zara',
      timeAgo: 'just now',
      artSeed: 'Nights',
    ),
    _RequestItem(
      title: 'Limerence',
      artist: 'Yves Tumor',
      duration: '3:18',
      requestedBy: 'zara',
      timeAgo: 'just now',
      artSeed: 'Limerence',
    ),
    _RequestItem(
      title: 'Midnight City',
      artist: 'M83',
      duration: '4:04',
      requestedBy: 'juno',
      timeAgo: 'just now',
      artSeed: 'Midnight City',
    ),
    _RequestItem(
      title: 'Crystalised',
      artist: 'The xx',
      duration: '3:21',
      requestedBy: 'sora',
      timeAgo: '1m',
      artSeed: 'Crystalised',
    ),
    _RequestItem(
      title: 'After Hours',
      artist: 'Kaytranada',
      duration: '3:31',
      requestedBy: 'deftone',
      timeAgo: '2m',
      artSeed: 'After Hours',
    ),
  ];

  static const _searchSongs = [
    _SearchSongItem(title: 'Von Dutch', artist: 'Charli xcx', duration: '2:48', artSeed: 'Von Dutch'),
    _SearchSongItem(title: 'Bad Decisions', artist: 'PinkPantheress', duration: '2:22', artSeed: 'Bad Decisions'),
    _SearchSongItem(title: 'After Hours', artist: 'Kaytranada', duration: '3:31', artSeed: 'After Hours'),
    _SearchSongItem(title: 'Midnight City', artist: 'M83', duration: '4:04', artSeed: 'Midnight City'),
    _SearchSongItem(title: 'Glue', artist: 'Bicep', duration: '5:18', artSeed: 'Glue'),
    _SearchSongItem(title: 'Nights', artist: 'Frank Ocean', duration: '5:07', artSeed: 'Nights'),
    _SearchSongItem(title: 'Simulation', artist: 'Skee Mask', duration: '4:46', artSeed: 'Simulation'),
    _SearchSongItem(title: 'Smalltown Boy', artist: 'Jamie xx edit', duration: '3:53', artSeed: 'Smalltown Boy'),
    _SearchSongItem(title: 'Limerence', artist: 'Yves Tumor', duration: '3:18', artSeed: 'Limerence'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.s4),
            _buildTabBar(context),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: _selectedTab == 0
                  ? _buildBoothTab(context)
                  : _buildRequestsTab(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(BuildContext context) {
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
                  '3AM in Tokyo',
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
            child: _buildTab('Requests · ${_requests.length}', 1),
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
          border: isSelected
              ? null
              : Border.all(color: AppColors.hairlineDark),
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

  Widget _buildBoothTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNowPlaying(context),
          const SizedBox(height: AppSpacing.s7),
          _buildUpNextHeader(context),
          const SizedBox(height: AppSpacing.s3),
          ..._queue.asMap().entries.map(
            (entry) => _buildQueueItem(context, entry.key, entry.value),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  // ── Now Playing ──

  Widget _buildNowPlaying(BuildContext context) {
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
                    seed: _currentSong.artSeed,
                    size: 80,
                    radius: AppRadius.sm,
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
                      _currentSong.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentSong.artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text2,
                      ),
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
              value: _progress,
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
                _currentSong.elapsed,
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
              Text(
                _currentSong.total,
                style: const TextStyle(color: AppColors.text2, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconButton(
                icon: Icons.skip_previous_rounded,
                onTap: () {},
              ),
              const SizedBox(width: AppSpacing.s5),
              GestureDetector(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
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
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.text,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s5),
              AppIconButton(
                icon: Icons.skip_next_rounded,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Up Next Header ──

  Widget _buildUpNextHeader(BuildContext context) {
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
          '${_queue.length}/5',
          style: const TextStyle(color: AppColors.text2, fontSize: 14),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showAddToQueueSheet(context),
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

  Widget _buildQueueItem(BuildContext context, int index, _QueueItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.hairlineDark),
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
          AlbumArtCover(seed: item.artSeed, size: 48, radius: AppRadius.xs),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
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
                    text: item.artist,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.text2,
                    ),
                    children: [
                      const TextSpan(text: ' · '),
                      TextSpan(
                        text: 'req @${item.requestedBy}',
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildSmallIconButton(
            icon: Icons.keyboard_arrow_up,
            color: AppColors.text2,
            onTap: () {},
          ),
          _buildSmallIconButton(
            icon: Icons.delete_outline,
            color: AppColors.danger,
            onTap: () {},
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listeners are requesting tracks. Accept to drop them into the queue.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.text2,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          ..._requests.map((r) => _buildRequestCard(context, r)),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, _RequestItem item) {
    final avatarSeed = item.requestedBy;
    final avatarColor = AppColors.generateBgColor(avatarSeed);

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
                seed: item.artSeed,
                size: 56,
                radius: AppRadius.sm,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.artist} · ${item.duration}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text2,
                      ),
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
                    avatarSeed[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.generateTextColor(avatarSeed),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  '@${item.requestedBy} · ${item.timeAgo}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.text2,
                  ),
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

  void _showAddToQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search Vibez Music...',
                                hintStyle: TextStyle(
                                  color: AppColors.text3,
                                  fontSize: 14,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchSongs.length,
                      itemBuilder: (context, index) {
                        final song = _searchSongs[index];
                        return _buildSearchSongTile(context, song);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
    );
  }

  Widget _buildSearchSongTile(BuildContext context, _SearchSongItem song) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        children: [
          AlbumArtCover(
            seed: song.artSeed,
            size: 48,
            radius: AppRadius.xs,
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
                  '${song.artist} · ${song.duration}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
