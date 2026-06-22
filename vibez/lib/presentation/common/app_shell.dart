import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/presentation/landing/widgets/miniplayer.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String location;

  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late String _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.location;
    AppRouter.instance.router.routerDelegate.addListener(_routeListener);
  }

  @override
  void dispose() {
    AppRouter.instance.router.routerDelegate.removeListener(_routeListener);
    super.dispose();
  }

  void _routeListener() {
    final newPath =
        AppRouter.instance.router.routeInformationProvider.value.uri.path;
    if (newPath.isNotEmpty && newPath != _currentPath) {
      if (mounted) {
        setState(() {
          _currentPath = newPath;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final hasCurrentSong = playback.currentSong != null;

    final bool isHome = _currentPath == RouteLocation.discover ||
        _currentPath == RouteLocation.profile;

    return SizedBox.expand(
      child: Stack(
        children: [
          widget.child,
          if (hasCurrentSong)
            Positioned(
              left: 16,
              right: 16,
              bottom: isHome
                  ? kBottomNavigationBarHeight * 2 - AppSpacing.s3
                  : (MediaQuery.paddingOf(context).bottom > 0
                      ? MediaQuery.paddingOf(context).bottom + 4
                      : 12),
              child: const Miniplayer(),
            ),
        ],
      ),
    );
  }
}
