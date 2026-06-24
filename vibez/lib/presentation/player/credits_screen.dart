import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';
import 'package:vibez/data/provider/playback_provider.dart' hide LoadState;
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';

class CreditsScreen extends ConsumerStatefulWidget {
  const CreditsScreen({super.key});

  @override
  ConsumerState<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends ConsumerState<CreditsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(songCacheProvider.notifier).loadCredits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackProvider);
    final cache = ref.watch(songCacheProvider);
    final currentSong = queue.currentSong;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s3),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s4,
              AppSpacing.s5,
              AppSpacing.s4,
            ),
            child: Row(
              children: [
                AlbumArtCover(
                  seed: currentSong?.title ?? 'Unknown',
                  size: 44,
                  radius: AppRadius.xs,
                  child:
                      currentSong?.thumbnail != null &&
                          currentSong!.thumbnail!.isNotEmpty
                      ? Image.network(
                          currentSong.thumbnail!,
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
                        currentSong?.title ?? 'Unknown',
                        style: Theme.of(context).textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () {
                          final artists = currentSong?.artists;
                          if (artists != null && artists.isNotEmpty && artists.first.id.isNotEmpty) {
                            final id = artists.first.id;
                            Navigator.pop(context);
                            Navigator.pop(context);
                            context.push('/artist/$id');
                          }
                        },
                        child: Text(
                          currentSong?.artists?.map((e) => e.name).join(', ') ??
                              '',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (currentSong?.album != null || currentSong?.albumId != null)
                        GestureDetector(
                          onTap: () {
                            final albumId = currentSong?.albumId ?? currentSong?.album?.id;
                            if (albumId != null && albumId.isNotEmpty) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              context.push('/album/$albumId');
                            }
                          },
                          child: Text(
                            currentSong?.album?.title ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.text3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(height: 0.5, color: AppColors.hairlineLight),

          Flexible(child: _buildBody(context, cache)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, SongCacheState cache) {
    switch (cache.creditsLoadState) {
      case LoadState.loading:
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.s9),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        );

      case LoadState.error:
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s9),
          child: Center(
            child: Text(
              "Couldn't load credits",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.text3),
            ),
          ),
        );

      case LoadState.success:
      case LoadState.idle:
        final credits = cache.currentCredits;
        if (credits == null || credits.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.s9),
            child: Center(
              child: Text(
                "No credits available",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.text3),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          itemCount: credits.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            child: Container(height: 0.5, color: AppColors.hairlineLight),
          ),
          itemBuilder: (context, index) {
            final credit = credits[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit.role.toUpperCase(),
                  style: Theme.of(context).textTheme.mono(
                    fontSize: 10,
                    color: AppColors.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                ...credit.entities.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      e.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            );
          },
        );
    }
  }
}
