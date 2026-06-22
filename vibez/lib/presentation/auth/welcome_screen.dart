import 'package:flutter/material.dart';
import 'package:vibez/core/router/app_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/presentation/auth/widgets/album_cover_background.dart';
import 'package:vibez/presentation/common/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AlbumCoverBackground(),
          Positioned(
            left: AppSpacing.s4,
            top: kToolbarHeight,
            child: AppTextLogo(size: LogoSize.small),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: AppSpacing.s8),
                    Text(
                      "Music is better\nwith people.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      "Join live rooms, vibe to a DJ in real time, or\nslip into a private session — just you and the\nsound.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s6),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          AppRouter.instance.push(RouteLocation.register);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(
                          "Create account",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s4),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          AppRouter.instance.push(RouteLocation.login);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.card,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(
                          "I already have an account",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: kBottomNavigationBarHeight),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
