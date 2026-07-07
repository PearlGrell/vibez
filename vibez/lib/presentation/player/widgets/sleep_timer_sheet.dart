import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/provider/playback_provider.dart';

void showSleepTimerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
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
    final active = state.sleepTimerActive;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: AppColors.hairlineLight, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.text3.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      active ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                      color: active ? AppColors.primary : AppColors.text,
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
                  ],
                ),
                const SizedBox(height: 16),
                if (active) _activeCard(state, notifier),
                if (active) const SizedBox(height: 20),
                Text(
                  active ? 'Change timer' : 'Set timer',
                  style: const TextStyle(
                    color: AppColors.text3,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final minutes in _presets)
                      _chip(
                        label: '$minutes min',
                        selected:
                            !state.sleepAfterTrack &&
                            _isActivePreset(state, minutes),
                        onTap: () {
                          notifier.setSleepTimer(Duration(minutes: minutes));
                          AppSnackbar.show(
                            message: 'Sleep timer set for $minutes min',
                            type: AppSnackType.success,
                          );
                        },
                      ),
                    _chip(
                      label: 'End of track',
                      icon: Icons.music_note_rounded,
                      selected: state.sleepAfterTrack,
                      onTap: () {
                        notifier.setSleepAtEndOfTrack();
                        AppSnackbar.show(
                          message: 'Will pause at end of track',
                          type: AppSnackType.success,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeCard(PlaybackState state, PlaybackProvider notifier) {
    final isCountdown = state.sleepTimerEnd != null;
    final big = isCountdown
        ? _formatRemaining(state.sleepTimerEnd!.difference(DateTime.now()))
        : 'End of track';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.mdBorderRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCountdown ? 'Pausing in' : 'Pausing at',
                style: const TextStyle(
                  color: AppColors.text3,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                big,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: isCountdown ? 30 : 22,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: AppColors.background.withValues(alpha: 0.6),
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.hairlineLight),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                notifier.cancelSleepTimer();
                AppSnackbar.show(
                  message: 'Sleep timer off',
                  type: AppSnackType.success,
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isActivePreset(PlaybackState state, int minutes) {
    final end = state.sleepTimerEnd;
    if (end == null) return false;
    final remaining = end.difference(DateTime.now());
    return remaining.inSeconds > (minutes - 1) * 60 &&
        remaining.inSeconds <= minutes * 60;
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.hairlineLight,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? AppColors.primary : AppColors.text2,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
