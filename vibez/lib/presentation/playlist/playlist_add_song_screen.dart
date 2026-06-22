import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/repositories/search_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/skeleton.dart';

class PlaylistAddSongScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistAddSongScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  ConsumerState<PlaylistAddSongScreen> createState() =>
      _PlaylistAddSongScreenState();
}

class _PlaylistAddSongScreenState extends ConsumerState<PlaylistAddSongScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<SearchSong> _results = [];
  bool _isLoading = false;
  final Set<String> _addedIds = {};
  final Set<String> _addingIds = {};

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    final result = await SearchRepository.instance.search(
      query.trim(),
      filter: SearchFilter.song,
    );
    if (mounted && _searchController.text.trim() == query.trim()) {
      setState(() {
        _results = result?.songs ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addSong(SearchSong song) async {
    if (_addingIds.contains(song.id) || _addedIds.contains(song.id)) return;
    setState(() => _addingIds.add(song.id));

    final success = await ref.read(userProvider.notifier).addSongToPlaylist(
      playlistId: widget.playlistId,
      songId: song.id,
    );

    if (mounted) {
      setState(() {
        _addingIds.remove(song.id);
        if (success) _addedIds.add(song.id);
      });
      AppSnackbar.show(
        message: success
            ? "Added '${song.title}' to ${widget.playlistName}"
            : "Failed to add song.",
        type: success ? AppSnackType.success : AppSnackType.error,
      );
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Add to ${widget.playlistName}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search for songs...',
                hintStyle: const TextStyle(color: AppColors.text3),
                prefixIcon: const Icon(Icons.search, color: AppColors.text3),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.text3),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardAlt,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.pillBorderRadius,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Search for songs to add',
          style: TextStyle(color: AppColors.text3, fontSize: 15),
        ),
      );
    }

    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            spacing: 12,
            children: [
              const Skeleton(height: 52, width: 52, borderRadius: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(height: 14, width: 160, borderRadius: 4),
                    const SizedBox(height: 8),
                    const Skeleton(height: 12, width: 100, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: AppColors.text3, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final song = _results[index];
        final isAdded = _addedIds.contains(song.id);
        final isAdding = _addingIds.contains(song.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AlbumArtCover(
                seed: song.title,
                size: 52,
                radius: 10,
                child: song.thumbnail.isNotEmpty
                    ? Image.network(
                        song.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.artists} • ${_formatDuration(song.duration)}',
                      style: const TextStyle(
                        color: AppColors.text2,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isAdding)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (isAdded)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 28)
              else
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.text2,
                    size: 28,
                  ),
                  onPressed: () => _addSong(song),
                ),
            ],
          ),
        );
      },
    );
  }
}
