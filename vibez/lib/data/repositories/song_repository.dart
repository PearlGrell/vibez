import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/playback_info.dart';
import 'package:vibez/data/models/lyrics.dart';
import 'package:vibez/data/models/related_song.dart';
import 'package:vibez/data/models/song_credits.dart';
import 'package:vibez/data/services/song_service.dart';
import 'package:vibez/data/services/stream_resolver_service.dart';

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
    final local = await StreamResolverService.instance.resolve(id);
    if (local != null) return local;

    final apiUrl = dotenv.get('API_URL', fallback: 'http://localhost:3000');
    return PlaybackInfo(
      id: id,
      playbackUrl: '$apiUrl/api/songs/$id/stream',
      mimeType: 'audio/mp4',
    );
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
