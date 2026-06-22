import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/artist.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/album.dart';
import 'package:vibez/data/services/artist_service.dart';

class ArtistRepository {
  static final ArtistRepository instance = ArtistRepository._();
  late final ArtistService _artistService;
  final Map<String, Artist> _artistCache = {};

  ArtistRepository._() {
    _artistService = ArtistService.instance;
  }

  Future<Artist?> getArtist(String id) async {
    if (_artistCache.containsKey(id)) {
      return _artistCache[id];
    }
    try {
      final res = await _artistService.getArtist(id);
      final artist = Artist.fromJson(res);
      _artistCache[id] = artist;
      return artist;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<List<Song>?> getArtistSongs(String id, String browseId) async {
    try {
      final res = await _artistService.getArtistSongs(id, browseId);
      final songsList = res['songs'] as List?;
      if (songsList == null) return [];
      return songsList
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<List<Album>?> getArtistAlbums(
    String id, {
    String? browseId,
    String? params,
  }) async {
    try {
      final res = await _artistService.getArtistAlbums(
        id,
        browseId: browseId,
        params: params,
      );
      final albumsList = res['albums'] as List?;
      if (albumsList == null) return [];
      return albumsList
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }
}
