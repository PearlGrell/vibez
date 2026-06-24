import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/models/album.dart';
import 'package:vibez/data/repositories/artist_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/skeleton.dart';
import 'package:vibez/presentation/landing/widgets/app_icon_button.dart';

class ArtistAlbumsScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? browseId;
  final String? params;

  const ArtistAlbumsScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.browseId,
    this.params,
  });

  @override
  ConsumerState<ArtistAlbumsScreen> createState() => _ArtistAlbumsScreenState();
}

class _ArtistAlbumsScreenState extends ConsumerState<ArtistAlbumsScreen> {
  List<Album> _albums = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  Future<void> _fetchAlbums() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final albums = await ArtistRepository.instance.getArtistAlbums(
        widget.artistId,
        browseId: widget.browseId,
        params: widget.params,
      );
      if (mounted) {
        setState(() {
          _albums = albums ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load albums.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.chevron_left,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          widget.artistName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.s4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(height: 160, width: double.infinity, borderRadius: 12),
              const SizedBox(height: 8),
              const Skeleton(height: 14, width: 120, borderRadius: 4),
              const SizedBox(height: 4),
              const Skeleton(height: 12, width: 80, borderRadius: 4),
            ],
          );
        },
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAlbums,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_albums.isEmpty) {
      return const Center(
        child: Text('No albums found.', style: TextStyle(color: AppColors.text2)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return GestureDetector(
          onTap: () {
            context.push('/album/${album.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AlbumArtCover(
                  seed: album.title,
                  size: double.infinity,
                  radius: AppRadius.sm,
                  child: album.thumbnail != null && album.thumbnail!.isNotEmpty
                      ? Image.network(
                          album.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "${album.year ?? ''} • ${album.type ?? 'Album'}",
                style: const TextStyle(
                  color: AppColors.text3,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
