import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/presentation/common/app_logo.dart';
import 'package:vibez/presentation/splash/widget/animated_progress_bar.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _fetchMe();
  }

  Future<bool> _hasInternet() async {
    try {
      final res = await InternetAddress.lookup('google.com');
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _fetchMe() async {
    final connected = await _hasInternet();
    if (!connected) {
      AppSnackbar.show(
        message: "Unable to connect to the internet.",
        actionLabel: "Retry",
        onAction: () => {_fetchMe()},
        duration: Duration(seconds: 100),
        type: AppSnackType.warning
      );
      return;
    }

    final meFuture = ref.read(userProvider.notifier).fetchMe();

    final steps = [0.3, 0.6, 0.85];
    for (final step in steps) {
      if (!mounted) return;
      setState(() {
        _progress = step;
      });
      await Future.delayed(const Duration(milliseconds: 350));
    }

    await meFuture;
    final user = ref.read(userProvider);
    if (!mounted) return;
    setState(() {
      _progress = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if(user != null) {
      ref.read(playbackProvider.notifier).loadLastPlayedSong();
    }

    AppRouter.instance.pushReplacement(
      user != null ? RouteLocation.discover : RouteLocation.welcome,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: AppTextLogo(size: LogoSize.medium)),
          Positioned(
            bottom: kBottomNavigationBarHeight,
            child: AnimatedProgressBar(progress: _progress),
          ),
        ],
      ),
    );
  }
}
