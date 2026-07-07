import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/utils/app_logger.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/artist.dart';
import 'package:vibez/data/models/playback_info.dart';
import 'package:vibez/data/models/lyrics.dart';
import 'package:vibez/data/models/song_credits.dart';
import 'package:vibez/data/repositories/song_repository.dart';

enum LoadState { idle, loading, success, error }

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  const CacheEntry({required this.data, required this.fetchedAt});
}

class SongCacheState {
  final Lyrics? currentLyrics;
  final List<Credit>? currentCredits;
  final List<Song> relatedSongs;
  final LoadState lyricsLoadState;
  final LoadState creditsLoadState;
  final LoadState relatedSongsLoadState;

  final String? activeSongId;

  const SongCacheState({
    this.currentLyrics,
    this.currentCredits,
    this.relatedSongs = const [],
    this.lyricsLoadState = LoadState.idle,
    this.creditsLoadState = LoadState.idle,
    this.relatedSongsLoadState = LoadState.idle,
    this.activeSongId,
  });

  SongCacheState copyWith({
    Lyrics? currentLyrics,
    List<Credit>? currentCredits,
    List<Song>? relatedSongs,
    LoadState? lyricsLoadState,
    LoadState? creditsLoadState,
    LoadState? relatedSongsLoadState,
    String? activeSongId,
    bool clear = false,
    bool clearLyrics = false,
    bool clearCredits = false,
  }) {
    if (clear) {
      return const SongCacheState();
    }
    return SongCacheState(
      currentLyrics: clearLyrics ? null : (currentLyrics ?? this.currentLyrics),
      currentCredits: clearCredits
          ? null
          : (currentCredits ?? this.currentCredits),
      relatedSongs: relatedSongs ?? this.relatedSongs,
      lyricsLoadState: lyricsLoadState ?? this.lyricsLoadState,
      creditsLoadState: creditsLoadState ?? this.creditsLoadState,
      relatedSongsLoadState:
          relatedSongsLoadState ?? this.relatedSongsLoadState,
      activeSongId: activeSongId ?? this.activeSongId,
    );
  }
}

final songCacheProvider = NotifierProvider<SongCacheProvider, SongCacheState>(
  SongCacheProvider.new,
);

class SongCacheProvider extends Notifier<SongCacheState> {
  final Map<String, CacheEntry<Song>> _songCache = {};
  final Map<String, CacheEntry<PlaybackInfo>> _playbackInfoCache = {};
  final Map<String, CacheEntry<List<Song>>> _relatedCache = {};
  final Map<String, CacheEntry<Lyrics>> _lyricsCache = {};
  final Map<String, CacheEntry<List<Credit>>> _creditsCache = {};

  final Map<String, Future<Song?>> _pendingSong = {};
  final Map<String, Future<PlaybackInfo?>> _pendingPlaybackInfo = {};
  final Map<String, Future<Lyrics?>> _pendingLyrics = {};
  final Map<String, Future<List<Credit>?>> _pendingCredits = {};
  final Map<String, Future<List<Song>?>> _pendingRelated = {};

  @override
  SongCacheState build() {
    _loadCacheFromDisk();
    return const SongCacheState();
  }

  static bool _isSongComplete(Song song) {
    if (song.duration <= 0) return false;
    final artists = song.artists;
    if (artists == null || artists.isEmpty) return false;
    if (artists.every((a) => a.id.isEmpty)) return false;
    return true;
  }

  Future<Song?> fetchSong(String id) {
    if (_songCache.containsKey(id) && _isSongComplete(_songCache[id]!.data)) {
      return Future.value(_songCache[id]!.data);
    }
    if (_pendingSong.containsKey(id)) return _pendingSong[id]!;

    final future = SongRepository.instance
        .getSong(id)
        .then((song) {
          _pendingSong.remove(id);
          if (song != null) {
            _songCache[id] = CacheEntry(data: song, fetchedAt: DateTime.now());
            _saveCacheToDisk();
          }
          return song;
        })
        .catchError((err) {
          _pendingSong.remove(id);
          throw err;
        });
    _pendingSong[id] = future;
    return future;
  }

  Future<PlaybackInfo?> fetchPlaybackInfo(String id) {
    if (_playbackInfoCache.containsKey(id)) {
      final entry = _playbackInfoCache[id]!;
      if (DateTime.now().difference(entry.fetchedAt) <
          const Duration(minutes: 30)) {
        return Future.value(entry.data);
      } else {
        _playbackInfoCache.remove(id);
      }
    }
    if (_pendingPlaybackInfo.containsKey(id)) {
      return _pendingPlaybackInfo[id]!;
    }

    final future = SongRepository.instance
        .getPlaybackUrl(id)
        .then((info) {
          _pendingPlaybackInfo.remove(id);
          if (info != null) {
            _playbackInfoCache[id] = CacheEntry(
              data: info,
              fetchedAt: DateTime.now(),
            );
          }
          return info;
        })
        .catchError((err) {
          _pendingPlaybackInfo.remove(id);
          throw err;
        });
    _pendingPlaybackInfo[id] = future;
    return future;
  }

  Future<List<Song>?> fetchRelated(String id) {
    if (_relatedCache.containsKey(id)) {
      return Future.value(_relatedCache[id]!.data);
    }
    if (_pendingRelated.containsKey(id)) return _pendingRelated[id]!;

    final future = SongRepository.instance
        .getRelated(id)
        .then((related) {
          _pendingRelated.remove(id);
          if (related != null) {
            final mapped = related
                .map(
                  (r) => Song(
                    id: r.id,
                    title: r.title,
                    duration: 0,
                    thumbnail: r.thumbnail,
                    artists: [Artist(id: '', name: r.artists)],
                  ),
                )
                .toList();

            _relatedCache[id] = CacheEntry(
              data: mapped,
              fetchedAt: DateTime.now(),
            );
            return mapped;
          }
          return null;
        })
        .catchError((err) {
          _pendingRelated.remove(id);
          throw err;
        });
    _pendingRelated[id] = future;
    return future;
  }

  void onSongChanged(String? songId, {bool isDownloadMode = false}) {
    if (songId == null) {
      state = const SongCacheState();
      return;
    }

    if (state.activeSongId == songId) return;

    final cachedLyrics = _lyricsCache[songId]?.data;
    final cachedCredits = _creditsCache[songId]?.data;
    final cachedRelated = _relatedCache[songId]?.data ?? const [];

    state = SongCacheState(
      activeSongId: songId,
      currentLyrics: cachedLyrics,
      currentCredits: cachedCredits,
      relatedSongs: cachedRelated,
      lyricsLoadState: cachedLyrics != null
          ? LoadState.success
          : LoadState.idle,
      creditsLoadState: cachedCredits != null
          ? LoadState.success
          : LoadState.idle,
      relatedSongsLoadState: cachedRelated.isNotEmpty
          ? LoadState.success
          : LoadState.idle,
    );

    if (!isDownloadMode) {
      Future.microtask(() => _loadDisplayData(songId));
    }
  }

  Future<void> loadLyrics() async {
    final songId = state.activeSongId;
    if (songId == null || state.currentLyrics != null) return;

    state = state.copyWith(lyricsLoadState: LoadState.loading);
    try {
      final lyrics = await _fetchLyrics(songId);
      if (state.activeSongId == songId) {
        state = state.copyWith(
          currentLyrics: lyrics,
          clearLyrics: lyrics == null,
          lyricsLoadState: lyrics != null ? LoadState.success : LoadState.idle,
        );
      }
    } catch (_) {
      if (state.activeSongId == songId) {
        state = state.copyWith(
          clearLyrics: true,
          lyricsLoadState: LoadState.idle,
        );
      }
    }
  }

  Future<void> loadCredits() async {
    final songId = state.activeSongId;
    if (songId == null || state.currentCredits != null) return;

    state = state.copyWith(creditsLoadState: LoadState.loading);
    try {
      final credits = await _fetchCredits(songId);
      if (state.activeSongId == songId) {
        state = state.copyWith(
          currentCredits: credits,
          creditsLoadState: credits != null
              ? LoadState.success
              : LoadState.error,
        );
      }
    } catch (_) {
      if (state.activeSongId == songId) {
        state = state.copyWith(creditsLoadState: LoadState.error);
      }
    }
  }

  Map<String, CacheEntry<Song>> get songCache => _songCache;

  void evictPlaybackInfo(String id) {
    _playbackInfoCache.remove(id);
    _pendingPlaybackInfo.remove(id);
  }

  void updateSongInCache(Song song) {
    if (_songCache.containsKey(song.id)) {
      final existing = _songCache[song.id]!.data;
      if (!_isSongComplete(existing) || _isSongComplete(song)) {
        _songCache[song.id] = CacheEntry(data: song, fetchedAt: DateTime.now());
        _saveCacheToDisk();
      }
    } else {
      _songCache[song.id] = CacheEntry(data: song, fetchedAt: DateTime.now());
      _saveCacheToDisk();
    }
  }

  Future<Lyrics?> _fetchLyrics(String id) {
    if (_lyricsCache.containsKey(id)) {
      return Future.value(_lyricsCache[id]!.data);
    }
    if (_pendingLyrics.containsKey(id)) return _pendingLyrics[id]!;

    final future = SongRepository.instance
        .getLyrics(id)
        .then((lyrics) {
          _pendingLyrics.remove(id);
          if (lyrics != null) {
            _lyricsCache[id] = CacheEntry(
              data: lyrics,
              fetchedAt: DateTime.now(),
            );
          }
          return lyrics;
        })
        .catchError((err) {
          _pendingLyrics.remove(id);
          throw err;
        });
    _pendingLyrics[id] = future;
    return future;
  }

  Future<List<Credit>?> _fetchCredits(String id) {
    if (_creditsCache.containsKey(id)) {
      return Future.value(_creditsCache[id]!.data);
    }
    if (_pendingCredits.containsKey(id)) return _pendingCredits[id]!;

    final future = SongRepository.instance
        .getCredits(id)
        .then((credits) {
          _pendingCredits.remove(id);
          if (credits != null) {
            _creditsCache[id] = CacheEntry(
              data: credits,
              fetchedAt: DateTime.now(),
            );
          }
          return credits;
        })
        .catchError((err) {
          _pendingCredits.remove(id);
          throw err;
        });
    _pendingCredits[id] = future;
    return future;
  }

  Future<void> _loadDisplayData(String songId) async {
    if (!_lyricsCache.containsKey(songId)) {
      state = state.copyWith(lyricsLoadState: LoadState.loading);
      try {
        final lyrics = await _fetchLyrics(songId);
        if (state.activeSongId == songId) {
          state = state.copyWith(
            currentLyrics: lyrics,
            clearLyrics: lyrics == null,
            lyricsLoadState: lyrics != null
                ? LoadState.success
                : LoadState.idle,
          );
        }
      } catch (_) {
        if (state.activeSongId == songId) {
          state = state.copyWith(
            clearLyrics: true,
            lyricsLoadState: LoadState.idle,
          );
        }
      }
    }

    if (!_creditsCache.containsKey(songId)) {
      state = state.copyWith(creditsLoadState: LoadState.loading);
      try {
        final credits = await _fetchCredits(songId);
        if (state.activeSongId == songId) {
          state = state.copyWith(
            currentCredits: credits,
            clearCredits: credits == null,
            creditsLoadState: credits != null
                ? LoadState.success
                : LoadState.idle,
          );
        }
      } catch (_) {
        if (state.activeSongId == songId) {
          state = state.copyWith(
            clearCredits: true,
            creditsLoadState: LoadState.idle,
          );
        }
      }
    }
  }

  Future<void> _loadCacheFromDisk() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/song_cache.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        data.forEach((key, value) {
          if (!_songCache.containsKey(key)) {
            final fetchedAt = DateTime.parse(value['fetchedAt']);
            final song = Song.fromJson(value['data']);
            _songCache[key] = CacheEntry(data: song, fetchedAt: fetchedAt);
          }
        });
      }
    } catch (e) {
      AppLogger.instance.error("", error: e);
    }
  }

  Future<void> _saveCacheToDisk() async {
    try {
      if (_songCache.length > 500) {
        final sortedKeys = _songCache.keys.toList()
          ..sort(
            (a, b) =>
                _songCache[b]!.fetchedAt.compareTo(_songCache[a]!.fetchedAt),
          );
        final keysToRemove = sortedKeys.skip(200);
        for (var k in keysToRemove) {
          _songCache.remove(k);
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/song_cache.json');
      final data = _songCache.map(
        (key, value) => MapEntry(key, {
          'fetchedAt': value.fetchedAt.toIso8601String(),
          'data': value.data.toJson(),
        }),
      );
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      AppLogger.instance.error("", error: e);
    }
  }
}
