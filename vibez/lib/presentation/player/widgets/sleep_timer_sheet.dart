import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/data/provider/playback_provider.dart';

/// Bottom sheet to arm/disarm the playback sleep timer. Presets pause after a
/// fixed duration; "End of track" pauses when the current song finishes.
void showSleepTimerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const SleepTimerSheet(),
  );
}

class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  Timer? _ticker;

  static const _presets = <int>[5, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    // Refresh once a second so the live countdown stays current.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackProvider);
    final notifier = ref.read(playbackProvider.notifier);

    String? statusLine;
    if (state.sleepTimerEnd != null) {
      final remaining = state.sleepTimerEnd!.difference(DateTime.now());
      statusLine = 'Pausing in ${_formatRemaining(remaining)}';
    } else if (state.sleepAfterTrack) {
      statusLine = 'Pausing at end of track';
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: AppColors.hairlineLight, width: 1),
          ),
        ),
        child: SafeArea(
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
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bedtime_outlined,
                      color: AppColors.text,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sleep timer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if (statusLine != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLine,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.hairlineLight, height: 1),
              const SizedBox(height: 4),
              for (final minutes in _presets)
                _tile(
                  context,
                  icon: Icons.timer_outlined,
                  title: '$minutes minutes',
                  selected:
                      state.sleepTimerEnd != null &&
                      !state.sleepAfterTrack &&
                      _isActivePreset(state, minutes),
                  onTap: () {
                    notifier.setSleepTimer(Duration(minutes: minutes));
                    Navigator.pop(context);
                  },
                ),
              _tile(
                context,
                icon: Icons.music_note_outlined,
                title: 'End of track',
                selected: state.sleepAfterTrack,
                onTap: () {
                  notifier.setSleepAtEndOfTrack();
                  Navigator.pop(context);
                },
              ),
              if (state.sleepTimerActive)
                _tile(
                  context,
                  icon: Icons.close_rounded,
                  title: 'Turn off',
                  iconColor: AppColors.danger,
                  onTap: () {
                    notifier.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // A preset is "active" only if the remaining time still fits within it, so
  // the checkmark tracks the currently armed preset without persisting which
  // one was picked.
  bool _isActivePreset(PlaybackState state, int minutes) {
    final end = state.sleepTimerEnd;
    if (end == null) return false;
    final remaining = end.difference(DateTime.now());
    return remaining.inSeconds > (minutes - 1) * 60 &&
        remaining.inSeconds <= minutes * 60;
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color iconColor = AppColors.text,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
