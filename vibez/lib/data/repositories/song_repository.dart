import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/playback_info.dart';
import 'package:vibez/data/models/lyrics.dart';
import 'package:vibez/data/models/related_song.dart';
import 'package:vibez/data/models/song_credits.dart';
import 'package:vibez/data/services/song_service.dart';

class SongRepository {
  static final SongRepository _songRepository = SongRepository._();
  late final SongService _songService;

  SongRepository._() {
    _songService = SongService.instance;
  }

  static SongRepository get instance => _songRepository;

  Future<Song?> getSong(String id) async {
    try {
      final res = await _songService.getSong(id);
      Song song = Song.fromJson(res);
      return song;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<PlaybackInfo?> getPlaybackUrl(String id) async {
    try {
      final res = await _songService.getPlaybackUrl(id);
      return PlaybackInfo.fromJson(res);
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<Lyrics?> getLyrics(String id) async {
    try {
      final res = await _songService.getLyrics(id);
      return Lyrics.fromJson(res);
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<List<RelatedSong>?> getRelated(String id) async {
    try {
      final res = await _songService.getRelated(id);
      final list = res['related'] as List?;
      if (list == null) return [];
      return list
          .map((e) => RelatedSong.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<List<Credit>?> getCredits(String id) async {
    try {
      final res = await _songService.getCredits(id);
      final list = res['credits'] as List?;
      if (list == null) return [];
      return list
          .map((e) => Credit.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }
}
