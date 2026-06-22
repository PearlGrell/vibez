import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/playlist.dart';
import 'package:vibez/data/services/playlist_service.dart';

class PlaylistRepository {
  static final PlaylistRepository instance = PlaylistRepository._();
  late final PlaylistService _playlistService;
  final Map<String, Playlist> _playlistCache = {};

  PlaylistRepository._() {
    _playlistService = PlaylistService.instance;
  }

  Future<Playlist?> getPlaylist(String id) async {
    if (_playlistCache.containsKey(id)) {
      return _playlistCache[id];
    }
    try {
      final res = await _playlistService.getPlaylist(id);
      final playlist = Playlist.fromJson(res);
      _playlistCache[id] = playlist;
      return playlist;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  void invalidateCache(String id) {
    _playlistCache.remove(id);
  }

  Future<Playlist?> createPlaylist({
    required String name,
    required bool private,
    required List<String> tags,
    required String createdById,
    String? thumbnail,
    String? description,
  }) async {
    try {
      final res = await _playlistService.createPlaylist(
        name: name,
        private: private,
        tags: tags,
        createdById: createdById,
        thumbnail: thumbnail,
        description: description,
      );
      final playlist = Playlist.fromJson(res);
      _playlistCache[playlist.id] = playlist;
      return playlist;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<Playlist?> updatePlaylist({
    required String id,
    String? name,
    bool? private,
    List<String>? tags,
    String? thumbnail,
    String? description,
  }) async {
    try {
      final res = await _playlistService.updatePlaylist(
        id: id,
        name: name,
        private: private,
        tags: tags,
        thumbnail: thumbnail,
        description: description,
      );
      final playlist = Playlist.fromJson(res);
      _playlistCache[playlist.id] = playlist;
      return playlist;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<Playlist?> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      final res = await _playlistService.addSongToPlaylist(
        playlistId: playlistId,
        songId: songId,
      );
      final playlist = Playlist.fromJson(res);
      _playlistCache[playlist.id] = playlist;
      return playlist;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }
}
