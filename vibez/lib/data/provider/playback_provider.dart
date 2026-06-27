import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/playback_info.dart';
import 'package:vibez/data/models/currently_playing.dart';
import 'package:vibez/data/models/recent_item.dart';
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/data/services/player_audio_service.dart';

enum RepeatMode { none, all, one }

enum LoadState { idle, loading, success, error }

class PlaybackState {
  final Song? currentSong;
  final PlaybackInfo? playbackInfo;
  final CurrentlyPlaying? currentlyPlaying;
  final bool playing;
  final RepeatMode repeatMode;
  final bool shuffle;

  final List<Song> queue;
  final List<Song> originalQueue;
  final List<Song> history;
  final List<Song> autoplayQueue;

  final List<Song> recentlyPlayed;
  final List<RecentItem> recentItems;

  final LoadState playbackLoadState;

  const PlaybackState({
    this.currentSong,
    this.playbackInfo,
    this.playing = false,
    this.currentlyPlaying,
    this.repeatMode = RepeatMode.none,
    this.shuffle = false,
    this.queue = const [],
    this.originalQueue = const [],
    this.history = const [],
    this.autoplayQueue = const [],
    this.recentlyPlayed = const [],
    this.recentItems = const [],
    this.playbackLoadState = LoadState.idle,
  });

  PlaybackState copyWith({
    Song? currentSong,
    PlaybackInfo? playbackInfo,
    bool? playing,
    RepeatMode? repeatMode,
    bool? shuffle,
    CurrentlyPlaying? currentlyPlaying,
    bool clearCurrentlyPlaying = false,
    List<Song>? queue,
    List<Song>? originalQueue,
    List<Song>? history,
    List<Song>? autoplayQueue,
    List<Song>? recentlyPlayed,
    List<RecentItem>? recentItems,
    LoadState? playbackLoadState,
    bool clearCurrentSong = false,
    bool clearPlaybackInfo = false,
  }) {
    return PlaybackState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      playbackInfo: clearCurrentSong || clearPlaybackInfo
          ? null
          : (playbackInfo ?? this.playbackInfo),
      playing: playing ?? this.playing,
      repeatMode: repeatMode ?? this.repeatMode,
      currentlyPlaying: clearCurrentlyPlaying
          ? null
          : (currentlyPlaying ?? this.currentlyPlaying),
      shuffle: shuffle ?? this.shuffle,
      queue: queue ?? this.queue,
      originalQueue: originalQueue ?? this.originalQueue,
      history: history ?? this.history,
      autoplayQueue: autoplayQueue ?? this.autoplayQueue,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      recentItems: recentItems ?? this.recentItems,
      playbackLoadState: clearCurrentSong
          ? LoadState.idle
          : (playbackLoadState ?? this.playbackLoadState),
    );
  }

  bool get hasNext => queue.isNotEmpty || autoplayQueue.isNotEmpty;
  bool get hasPrevious => history.isNotEmpty;
  int get queueLength => queue.length;
  Duration get remainingDuration =>
      Duration(seconds: queue.fold(0, (sum, song) => sum + song.duration));
}

final playbackProvider = NotifierProvider<PlaybackProvider, PlaybackState>(
  PlaybackProvider.new,
);

class PlaybackProvider extends Notifier<PlaybackState> {
  final _random = Random();
  bool _playingFromCollection = false;

  @override
  PlaybackState build() {
    return const PlaybackState();
  }

  void play() {
    PlayerAudioService.handler.play();
  }

  void pause() {
    PlayerAudioService.handler.pause();
  }

  void togglePlay() {
    state.playing ? pause() : play();
  }

  void setPlayingState(bool isPlaying) {
    if (state.playing != isPlaying) {
      state = state.copyWith(playing: isPlaying);
    }
  }

  Future<void> playSong(Song song) async {
    state = state.copyWith(
      currentSong: song,
      playing: true,
      queue: const [],
      originalQueue: const [],
      autoplayQueue: const [],
      history: const [],
      clearPlaybackInfo: true,
      playbackLoadState: LoadState.loading,
    );
    await _loadAndPlay(song);
  }

  Future<void> playSongsFromList(List<Song> songs, int startIndex) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    final current = songs[startIndex];
    final remainingQueue = songs.sublist(startIndex + 1);
    final history = songs.sublist(0, startIndex).reversed.toList();

    state = state.copyWith(
      currentSong: current,
      playing: true,
      queue: remainingQueue,
      originalQueue: remainingQueue,
      autoplayQueue: const [],
      history: history,
      clearPlaybackInfo: true,
      playbackLoadState: LoadState.loading,
    );
    _playingFromCollection = true;
    await _loadAndPlay(current);
  }

  Future<void> playSongById(String songId) async {
    final song = await ref.read(songCacheProvider.notifier).fetchSong(songId);
    if (song != null) {
      await playSong(song);
    }
  }

  Future<void> playNext() async {
    if (state.repeatMode == RepeatMode.one && state.currentSong != null) {
      await _loadAndPlay(state.currentSong!);
      return;
    }

    final newHistory = state.currentSong != null
        ? [state.currentSong!, ...state.history].take(50).toList()
        : state.history;

    if (state.queue.isNotEmpty) {
      final nextSong = state.queue.first;
      final remainingQueue = state.queue.sublist(1);
      final newOriginalQueue = state.shuffle
          ? state.originalQueue.where((s) => s.id != nextSong.id).toList()
          : List<Song>.from(remainingQueue);

      state = state.copyWith(
        currentSong: nextSong,
        playing: true,
        queue: remainingQueue,
        originalQueue: newOriginalQueue,
        history: newHistory,
        clearPlaybackInfo: true,
        playbackLoadState: LoadState.loading,
      );
      await _loadAndPlay(nextSong);
      return;
    }

    if (state.repeatMode == RepeatMode.all) {
      final seenIds = <String>{};
      final uniqueHistory = <Song>[];
      for (final song in state.history.reversed) {
        if (!seenIds.contains(song.id)) {
          uniqueHistory.add(song);
          seenIds.add(song.id);
        }
      }
      if (state.currentSong != null &&
          !seenIds.contains(state.currentSong!.id)) {
        uniqueHistory.add(state.currentSong!);
      }
      if (uniqueHistory.isNotEmpty) {
        final nextSong = uniqueHistory.first;
        final remainingQueue = uniqueHistory.sublist(1);
        state = state.copyWith(
          currentSong: nextSong,
          playing: true,
          queue: remainingQueue,
          originalQueue: remainingQueue,
          history: const [],
          clearPlaybackInfo: true,
          playbackLoadState: LoadState.loading,
        );
        await _loadAndPlay(nextSong);
        return;
      }
    }

    if (state.autoplayQueue.isNotEmpty) {
      final nextSong = state.autoplayQueue.first;
      final remainingAutoplay = state.autoplayQueue.sublist(1);
      state = state.copyWith(
        currentSong: nextSong,
        playing: true,
        history: newHistory,
        autoplayQueue: remainingAutoplay,
        clearPlaybackInfo: true,
        playbackLoadState: LoadState.loading,
      );
      await _loadAndPlay(nextSong);
      return;
    }

    state = state.copyWith(playing: false);
    await PlayerAudioService.handler.pause();
    await PlayerAudioService.handler.seek(Duration.zero);
  }

  Future<void> playPrevious() async {
    if (state.history.isEmpty) return;

    final prevSong = state.history.first;
    final remainingHistory = state.history.sublist(1);

    final newQueue = state.currentSong != null
        ? [state.currentSong!, ...state.queue]
        : state.queue;
    final newOriginalQueue = state.currentSong != null
        ? [state.currentSong!, ...state.originalQueue]
        : state.originalQueue;

    state = state.copyWith(
      currentSong: prevSong,
      playing: true,
      queue: newQueue,
      originalQueue: newOriginalQueue,
      history: remainingHistory,
      clearPlaybackInfo: true,
      playbackLoadState: LoadState.loading,
    );
    await _loadAndPlay(prevSong);
  }

  Future<void> playSongFromQueue(Song song) async {
    final index = state.queue.indexWhere((s) => s.id == song.id);
    if (index == -1) return;

    final songsToHistory = state.queue.sublist(0, index);
    final nextSong = state.queue[index];
    final remainingQueue = state.queue.sublist(index + 1);

    final newHistory = [
      ...songsToHistory.reversed,
      if (state.currentSong != null) state.currentSong!,
      ...state.history,
    ].take(50).toList();

    state = state.copyWith(
      currentSong: nextSong,
      playing: true,
      queue: remainingQueue,
      originalQueue: remainingQueue,
      history: newHistory,
      clearPlaybackInfo: true,
      playbackLoadState: LoadState.loading,
    );
    await _loadAndPlay(nextSong);
  }

  void addToQueue(Song song) {
    if (state.queue.any((s) => s.id == song.id)) return;
    state = state.copyWith(
      queue: [...state.queue, song],
      originalQueue: [...state.originalQueue, song],
    );
  }

  void addSongsToQueue(List<Song> songs) {
    final seenIds = state.queue.map((s) => s.id).toSet();
    final unique = songs.where((s) => !seenIds.contains(s.id)).toList();
    if (unique.isEmpty) return;
    state = state.copyWith(
      queue: [...state.queue, ...unique],
      originalQueue: [...state.originalQueue, ...unique],
    );
  }

  void addToQueueNext(Song song) {
    if (state.queue.any((s) => s.id == song.id)) return;
    state = state.copyWith(
      queue: [song, ...state.queue],
      originalQueue: [song, ...state.originalQueue],
    );
  }

  void addSongsToQueueNext(List<Song> songs) {
    final seenIds = state.queue.map((s) => s.id).toSet();
    final unique = songs.where((s) => !seenIds.contains(s.id)).toList();
    if (unique.isEmpty) return;
    state = state.copyWith(
      queue: [...unique, ...state.queue],
      originalQueue: [...unique, ...state.originalQueue],
    );
  }

  void removeFromQueue(String songId) {
    state = state.copyWith(
      queue: state.queue.where((s) => s.id != songId).toList(),
      originalQueue: state.originalQueue.where((s) => s.id != songId).toList(),
    );
  }

  void removeFromQueueAt(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final songToRemove = state.queue[index];
    final newQueue = [...state.queue]..removeAt(index);
    state = state.copyWith(
      queue: newQueue,
      originalQueue: state.originalQueue
          .where((s) => s.id != songToRemove.id)
          .toList(),
    );
  }

  void moveInQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;
    if (newIndex < 0 || newIndex >= state.queue.length) return;
    final newQueue = [...state.queue];
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);
    state = state.copyWith(
      queue: newQueue,
      originalQueue: state.shuffle ? state.originalQueue : newQueue,
    );
  }

  void clearQueue() {
    state = state.copyWith(
      queue: const [],
      originalQueue: const [],
      autoplayQueue: const [],
    );
  }

  void setAutoplayQueue(List<Song> songs) {
    final seenIds = <String>{};
    if (state.currentSong != null) seenIds.add(state.currentSong!.id);
    for (final s in state.history) {
      seenIds.add(s.id);
    }
    for (final s in state.queue) {
      seenIds.add(s.id);
    }

    final filtered = songs.where((s) => !seenIds.contains(s.id)).toList();
    state = state.copyWith(autoplayQueue: filtered);
  }

  void appendAutoplaySongs(List<Song> songs) {
    final seenIds = <String>{};
    if (state.currentSong != null) seenIds.add(state.currentSong!.id);
    for (final s in state.history) {
      seenIds.add(s.id);
    }
    for (final s in state.queue) {
      seenIds.add(s.id);
    }
    for (final s in state.autoplayQueue) {
      seenIds.add(s.id);
    }

    final filtered = songs.where((s) => !seenIds.contains(s.id)).toList();
    if (filtered.isNotEmpty) {
      state = state.copyWith(
        autoplayQueue: [...state.autoplayQueue, ...filtered],
      );
    }
  }

  void toggleShuffle() {
    final newShuffle = !state.shuffle;
    if (newShuffle) {
      final shuffled = [...state.queue]..shuffle(_random);
      state = state.copyWith(
        shuffle: true,
        queue: shuffled,
        originalQueue: state.queue,
      );
    } else {
      state = state.copyWith(
        shuffle: false,
        queue: state.originalQueue,
        originalQueue: state.originalQueue,
      );
    }
  }

  void setCurrentlyPlaying(CurrentlyPlaying? source) {
    state = state.copyWith(
      currentlyPlaying: source,
      clearCurrentlyPlaying: source == null,
    );
    if (source != null && source.type != PlayingSourceType.song) {
      _addRecentItem(
        RecentItem(
          id: source.sourceId,
          name: source.sourceName,
          thumbnail: source.thumbnail,
          type: RecentItemType.values.byName(source.type.name),
        ),
      );
    }
  }

  void setRepeatMode(RepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
  }

  void toggleRepeatMode() {
    final nextMode = RepeatMode
        .values[(state.repeatMode.index + 1) % RepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
  }

  void toggleAutoplay() {
    if (state.currentSong != null) {
      _loadRelatedForAutoplay(state.currentSong!.id);
    }
  }

  Future<void> retryCurrentSong() async {
    final song = state.currentSong;
    if (song == null) return;
    state = state.copyWith(playbackLoadState: LoadState.loading);
    await _loadAndPlay(song);
  }

  void stopAndClear() {
    PlayerAudioService.handler.stop();
  }

  void clearStateForStop() {
    state = state.copyWith(clearCurrentSong: true, playing: false);
  }

  void updateCurrentSongDuration(Duration duration) {
    if (state.currentSong != null &&
        state.currentSong!.duration != duration.inSeconds) {
      final updatedSong = state.currentSong!.copyWith(
        duration: duration.inSeconds,
      );
      state = state.copyWith(currentSong: updatedSong);
      ref.read(songCacheProvider.notifier).updateSongInCache(updatedSong);
    }
  }

  Future<void> _loadAndPlay(Song song) async {
    final cache = ref.read(songCacheProvider.notifier);
    final handler = PlayerAudioService.vibezHandler;

    handler.updateMetadata(song);
    _saveCurrentSong(song);

    try {
      final playbackInfo = await cache.fetchPlaybackInfo(song.id);
      if (state.currentSong?.id != song.id) return;

      if (playbackInfo != null) {
        state = state.copyWith(
          playbackInfo: playbackInfo,
          playbackLoadState: LoadState.success,
        );
        await handler.playUrl(song, playbackInfo.playbackUrl);

        _loadRelatedForAutoplay(song.id);
      } else {
        state = state.copyWith(playbackLoadState: LoadState.error);
      }
    } catch (_) {
      if (state.currentSong?.id == song.id) {
        state = state.copyWith(playbackLoadState: LoadState.error);
      }
    }
  }

  Future<void> _loadRelatedForAutoplay(String songId) async {
    final cache = ref.read(songCacheProvider.notifier);
    try {
      final related = await cache.fetchRelated(songId);
      if (related != null && state.currentSong?.id == songId) {
        setAutoplayQueue(related);
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentSong', song.id);
    _addToRecentlyPlayed(song, prefs);
  }

  void _addToRecentlyPlayed(Song song, SharedPreferences prefs) {
    final updated = [
      song,
      ...state.recentlyPlayed.where((s) => s.id != song.id),
    ].take(30).toList();
    state = state.copyWith(recentlyPlayed: updated);

    final encoded = jsonEncode(updated.map((s) => s.toJson()).toList());
    prefs.setString('recentlyPlayed', encoded);

    final skipSongItem =
        _playingFromCollection ||
        (state.currentlyPlaying != null &&
            state.currentlyPlaying!.type != PlayingSourceType.song);
    if (!skipSongItem) {
      _addRecentItem(
        RecentItem(
          id: song.id,
          name: song.title,
          thumbnail: song.thumbnail,
          type: RecentItemType.song,
        ),
      );
    }
  }

  void _addRecentItem(RecentItem item) {
    final key = '${item.type.name}_${item.id}';
    final updated = [
      item,
      ...state.recentItems.where((r) => '${r.type.name}_${r.id}' != key),
    ].take(30).toList();
    state = state.copyWith(recentItems: updated);
    _saveRecentItems(updated);
  }

  Future<void> _saveRecentItems(List<RecentItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'recentItems',
      jsonEncode(items.map((i) => i.toJson()).toList()),
    );
  }

  Future<void> loadLastPlayedSong() async {
    final prefs = await SharedPreferences.getInstance();

    final rpJson = prefs.getString('recentlyPlayed');
    if (rpJson != null) {
      try {
        final list = (jsonDecode(rpJson) as List)
            .map((e) => Song.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(recentlyPlayed: list);
      } catch (_) {}
    }

    final riJson = prefs.getString('recentItems');
    if (riJson != null) {
      try {
        final list = (jsonDecode(riJson) as List)
            .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(recentItems: list);
      } catch (_) {}
    }

    final songId = prefs.getString('currentSong');
    if (songId != null) {
      final cache = ref.read(songCacheProvider.notifier);
      final song = await cache.fetchSong(songId);
      if (song != null) {
        state = state.copyWith(
          currentSong: song,
          playing: false,
          currentlyPlaying: CurrentlyPlaying(
            sourceId: song.id,
            sourceName: song.title,
            type: PlayingSourceType.song,
            thumbnail: song.thumbnail,
          ),
        );
      }
    }
  }
}
