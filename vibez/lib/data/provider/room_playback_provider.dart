import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/core/network/api_client.dart';
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/data/services/player_audio_service.dart';

class RoomPlaybackState {
  final Song? currentSong;
  final bool playing;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final LoadState playbackLoadState;

  const RoomPlaybackState({
    this.currentSong,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.playbackLoadState = LoadState.idle,
  });

  RoomPlaybackState copyWith({
    Song? currentSong,
    bool? playing,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    LoadState? playbackLoadState,
    bool clearCurrentSong = false,
  }) {
    return RoomPlaybackState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      playbackLoadState: clearCurrentSong ? LoadState.idle : (playbackLoadState ?? this.playbackLoadState),
    );
  }
}

final roomPlaybackProvider = NotifierProvider.autoDispose<RoomPlaybackNotifier, RoomPlaybackState>(
  RoomPlaybackNotifier.new,
);

class RoomPlaybackNotifier extends Notifier<RoomPlaybackState> {
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _bufferedPositionSub;
  StreamSubscription? _playingSub;
  Timer? _syncTimer;

  String? _currentLoadedSongId;
  Duration _serverTimeOffset = Duration.zero;

  @override
  RoomPlaybackState build() {
    final roomId = ref.watch(activeRoomIdProvider);

    if (roomId == null) {
      _syncTimer?.cancel();
      _syncTimer = null;
      _cancelSubscriptions();
      _currentLoadedSongId = null;
      _serverTimeOffset = Duration.zero;
      Future.microtask(() {
        PlayerAudioService.roomHandler.stopLocal();
        PlayerAudioService.switchToPlayer();
      });
      return const RoomPlaybackState();
    }

    ref.onDispose(() {
      _syncTimer?.cancel();
      _syncTimer = null;
      _cancelSubscriptions();
      _currentLoadedSongId = null;
      _serverTimeOffset = Duration.zero;
      PlayerAudioService.roomHandler.stopLocal();
      PlayerAudioService.switchToPlayer();
    });

    Future.microtask(() {
      PlayerAudioService.switchToRoom();
    });

    if (_positionSub == null) {
      _setupSubscriptions();
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final rId = ref.read(activeRoomIdProvider);
        if (rId != null) {
          final room = ref.read(roomProvider(rId)).room;
          if (room != null) {
            _syncPlayback(room.startedAt, room.playing);
          }
        }
      });
      Future.microtask(() async {
        final offset = await ApiClient.instance.getServerTimeOffset();
        _serverTimeOffset = offset;
        final currentRoom = ref.read(roomProvider(roomId)).room;
        if (currentRoom != null) {
          _syncPlayback(currentRoom.startedAt, currentRoom.playing);
        }
      });
    }

    ref.listen(roomProvider(roomId), (previous, next) {
      final room = next.room;
      if (room != null) {
        final currentSong = room.currentSong;
        if (currentSong != null) {
          if (_currentLoadedSongId != currentSong.id) {
            _currentLoadedSongId = currentSong.id;
            _loadAndPlay(currentSong, room.startedAt, room.playing);
          } else {
            _syncPlayback(room.startedAt, room.playing);
          }
        } else {
          _currentLoadedSongId = null;
          PlayerAudioService.roomHandler.stopLocal();
          state = state.copyWith(clearCurrentSong: true, playing: false);
        }
      }
    });

    final initialRoom = ref.read(roomProvider(roomId)).room;
    if (initialRoom != null) {
      final currentSong = initialRoom.currentSong;
      if (currentSong != null) {
        _currentLoadedSongId = currentSong.id;
        Future.microtask(() => _loadAndPlay(currentSong, initialRoom.startedAt, initialRoom.playing));
      }
    }

    return RoomPlaybackState(
      currentSong: initialRoom?.currentSong,
      playing: PlayerAudioService.roomHandler.playbackState.value.playing,
      position: PlayerAudioService.roomHandler.position,
      duration: Duration(seconds: initialRoom?.currentSong?.duration ?? 0),
      bufferedPosition: PlayerAudioService.roomHandler.playbackState.value.bufferedPosition,
    );
  }

  void _setupSubscriptions() {
    _cancelSubscriptions();

    final roomHandler = PlayerAudioService.roomHandler;

    _positionSub = roomHandler.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durationSub = roomHandler.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    _bufferedPositionSub = roomHandler.bufferedPositionStream.listen((buf) {
      state = state.copyWith(bufferedPosition: buf);
    });

    _playingSub = roomHandler.playingStream.listen((playing) {
      state = state.copyWith(playing: playing);
    });
  }

  void _cancelSubscriptions() {
    _positionSub?.cancel();
    _positionSub = null;
    _durationSub?.cancel();
    _durationSub = null;
    _bufferedPositionSub?.cancel();
    _bufferedPositionSub = null;
    _playingSub?.cancel();
    _playingSub = null;
  }

  Future<void> _loadAndPlay(Song song, DateTime? startedAt, bool shouldPlay) async {
    state = state.copyWith(
      currentSong: song,
      playbackLoadState: LoadState.loading,
    );

    try {
      final cache = ref.read(songCacheProvider.notifier);
      final playbackInfo = await cache.fetchPlaybackInfo(song.id);

      if (playbackInfo != null) {
        state = state.copyWith(playbackLoadState: LoadState.success);
        
        await PlayerAudioService.roomHandler.playUrl(
          song,
          playbackInfo.playbackUrl,
          startedAt,
          _serverTimeOffset,
          shouldPlay,
          headers: playbackInfo.headers,
          mimeType: playbackInfo.mimeType,
        );
      } else {
        state = state.copyWith(playbackLoadState: LoadState.error);
      }
    } catch (_) {
      state = state.copyWith(playbackLoadState: LoadState.error);
    }
  }

  void _syncPlayback(DateTime? startedAt, bool shouldPlay) {
    final roomHandler = PlayerAudioService.roomHandler;
    final isPlaying = roomHandler.playbackState.value.playing;

    if (shouldPlay) {
      if (!isPlaying) {
        roomHandler.play();
      }
      
      if (startedAt != null) {
        final serverTime = DateTime.now().add(_serverTimeOffset);
        final elapsed = serverTime.difference(startedAt);
        final currentPos = roomHandler.position;
        final driftMs = (elapsed - currentPos).inMilliseconds.abs();
        if (driftMs > 300) {
          roomHandler.seek(elapsed);
        }
      }
    } else {
      if (isPlaying) {
        roomHandler.pause();
      }
    }
  }
}
