import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';

enum AppSnackType { success, error, info, warning }

class AppSnackbar {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static OverlayEntry? _currentEntry;

  static void show({
    required String message,
    String? title,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showClose = false,
  }) {
    final navigatorState = AppRouter.instance.router.routerDelegate.navigatorKey.currentState;
    if (navigatorState == null) return;

    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (context) {
        return _TopSnackbarOverlay(
          message: message,
          title: title,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction,
          showClose: showClose,
          duration: duration,
          onDismissed: () {
            if (_currentEntry != null) {
              _currentEntry!.remove();
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    navigatorState.overlay?.insert(entry);
  }

  static ({Color color, IconData icon}) _palette(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return (color: AppColors.success, icon: Icons.check_rounded);
      case AppSnackType.error:
        return (color: AppColors.danger, icon: Icons.close_rounded);
      case AppSnackType.warning:
        return (
          color: AppColors.warn,
          icon: Icons.priority_high_rounded,
        );
      case AppSnackType.info:
        return (
          color: AppColors.primary,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _TopSnackbarOverlay extends StatefulWidget {
  final String message;
  final String? title;
  final AppSnackType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showClose;
  final VoidCallback onDismissed;
  final Duration duration;

  const _TopSnackbarOverlay({
    required this.message,
    this.title,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.showClose = false,
    required this.onDismissed,
    required this.duration,
  });

  @override
  State<_TopSnackbarOverlay> createState() => _TopSnackbarOverlayState();
}

class _TopSnackbarOverlayState extends State<_TopSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _offsetAnimation = Tween<Offset>(
            begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _timer = Timer(widget.duration, () => dismiss());
  }

  void dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) widget.onDismissed();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppSnackbar._palette(widget.type);
    final accent = palette.color;

    final surface = dark ? AppColors.card : Colors.white;
    final border = dark ? AppColors.hairlineDark : const Color(0x14000000);
    final primaryText = dark ? AppColors.text : const Color(0xFF18181B);
    final mutedText = dark ? AppColors.text2 : const Color(0xFF6B6B72);
    final hasTitle = widget.title != null && widget.title!.trim().isNotEmpty;

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                palette.icon,
                                color: dark
                                    ? const Color(0xFF18181B)
                                    : Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasTitle) ...[
                                    Text(
                                      widget.title!,
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.1,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      color:
                                          hasTitle ? mutedText : primaryText,
                                      fontSize: hasTitle ? 13 : 14,
                                      fontWeight: hasTitle
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                      letterSpacing: -0.1,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.actionLabel != null &&
                                widget.onAction != null) ...[
                              const SizedBox(width: 12),
                              _Action(
                                label: widget.actionLabel!,
                                color: accent,
                                onTap: () {
                                  dismiss();
                                  widget.onAction!();
                                },
                              ),
                            ] else if (widget.showClose) ...[
                              const SizedBox(width: 8),
                              _Close(
                                color: mutedText,
                                onTap: dismiss,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _Close extends StatelessWidget {
  const _Close({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, size: 16, color: color),
        ),
      ),
    );
  }
}
