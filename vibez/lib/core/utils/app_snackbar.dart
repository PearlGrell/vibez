import 'package:flutter/material.dart';

enum AppSnackType { success, error, info, warning }

class AppSnackbar {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    String? title,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showClose = false,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final ctx = messengerKey.currentContext;
    final dark = ctx != null
        ? Theme.of(ctx).brightness == Brightness.dark
        : true;

    final palette = _palette(type);
    final accent = palette.color;

    final surface = dark ? const Color(0xFF1C1C1F) : Colors.white;
    final border = dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0x14000000);
    final primaryText = dark
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF18181B);
    final mutedText = dark ? const Color(0xFF9A9AA2) : const Color(0xFF6B6B72);

    final hasTitle = title != null && title.trim().isNotEmpty;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.45 : 0.07),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: hasTitle
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: dark ? 0.16 : 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(palette.icon, color: accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasTitle) ...[
                              Text(
                                title,
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
                              message,
                              style: TextStyle(
                                color: hasTitle ? mutedText : primaryText,
                                fontSize: hasTitle ? 13 : 14,
                                fontWeight: hasTitle
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                                letterSpacing: -0.1,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(width: 8),
                        _Action(
                          label: actionLabel,
                          color: accent,
                          onTap: () {
                            messenger.hideCurrentSnackBar();
                            onAction();
                          },
                        ),
                      ] else if (showClose) ...[
                        const SizedBox(width: 4),
                        _Close(
                          color: mutedText,
                          onTap: messenger.hideCurrentSnackBar,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  static ({Color color, IconData icon}) _palette(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return (color: const Color(0xFF22C55E), icon: Icons.check_rounded);
      case AppSnackType.error:
        return (color: const Color(0xFFEF4444), icon: Icons.close_rounded);
      case AppSnackType.warning:
        return (
          color: const Color(0xFFF59E0B),
          icon: Icons.priority_high_rounded,
        );
      case AppSnackType.info:
        return (
          color: const Color(0xFF3B82F6),
          icon: Icons.info_outline_rounded,
        );
    }
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
