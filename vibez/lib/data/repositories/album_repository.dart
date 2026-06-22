import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/album.dart';
import 'package:vibez/data/services/album_service.dart';

class AlbumRepository {
  static final AlbumRepository instance = AlbumRepository._();
  late final AlbumService _albumService;
  final Map<String, Album> _albumCache = {};

  AlbumRepository._() {
    _albumService = AlbumService.instance;
  }

  Future<Album?> getAlbum(String id) async {
    if (_albumCache.containsKey(id)) {
      return _albumCache[id];
    }
    try {
      final res = await _albumService.getAlbum(id);
      final album = Album.fromJson(res);
      _albumCache[id] = album;
      return album;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: .error);
      return null;
    }
  }
}
