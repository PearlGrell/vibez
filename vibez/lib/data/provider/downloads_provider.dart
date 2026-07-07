import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/data/services/download_service.dart';

class DownloadsState {
  final List<Song> songs;
  final Set<String> downloading;

  const DownloadsState({this.songs = const [], this.downloading = const {}});

  bool isDownloaded(String id) => songs.any((s) => s.id == id);
  bool isDownloading(String id) => downloading.contains(id);

  DownloadsState copyWith({List<Song>? songs, Set<String>? downloading}) {
    return DownloadsState(
      songs: songs ?? this.songs,
      downloading: downloading ?? this.downloading,
    );
  }
}

final downloadsProvider = NotifierProvider<DownloadsProvider, DownloadsState>(
  DownloadsProvider.new,
);

class DownloadsProvider extends Notifier<DownloadsState> {
  static const _key = 'downloads';

  @override
  DownloadsState build() {
    _load();
    return const DownloadsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return;
    try {
      final list = (jsonDecode(json) as List)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();

      final existing = list
          .where((s) => DownloadService.isDownloaded(s.id))
          .toList();
      state = state.copyWith(songs: existing);
      if (existing.length != list.length) _persist(existing);
    } catch (_) {}
  }

  Future<bool> downloadSong(Song song) async {
    if (state.isDownloaded(song.id) || state.isDownloading(song.id)) {
      return true;
    }
    state = state.copyWith(downloading: {...state.downloading, song.id});
    try {
      final info = await ref
          .read(songCacheProvider.notifier)
          .fetchPlaybackInfo(song.id);
      if (info != null) {
        final ok = await DownloadService.download(
          song.id,
          info.playbackUrl,
          headers: info.headers,
        );
        if (ok) {
          final songs = [song, ...state.songs.where((s) => s.id != song.id)];
          state = state.copyWith(songs: songs, downloading: _without(song.id));
          _persist(songs);
          return true;
        }
      }
    } catch (_) {}
    state = state.copyWith(downloading: _without(song.id));
    return false;
  }

  Future<void> removeDownload(String songId) async {
    await DownloadService.remove(songId);
    final songs = state.songs.where((s) => s.id != songId).toList();
    state = state.copyWith(songs: songs);
    _persist(songs);
  }

  Set<String> _without(String id) =>
      state.downloading.where((e) => e != id).toSet();

  Future<void> _persist(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(songs.map((s) => s.toJson()).toList()),
    );
  }
}
