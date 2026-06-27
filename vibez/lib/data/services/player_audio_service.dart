import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:audio_service/audio_service.dart' as audio;
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/song_cache_provider.dart' hide LoadState;
import 'package:vibez/data/services/room_audio_service.dart';

class PlayerAudioHandler extends audio.BaseAudioHandler with audio.SeekHandler {
  final ProviderContainer _container;
  final AudioPlayer _player = AudioPlayer();

  bool _retrying = false;

  PlayerAudioHandler(this._container) {
    _player.playbackEventStream
        .map(_transformEvent)
        .listen(
          playbackState.add,
          onError: (Object e, StackTrace stackTrace) {
            _handlePlayerError();
          },
        );

    _player.processingStateStream.listen(
      (state) {
        if (state == ProcessingState.completed) {
          final playbackState = _container.read(playbackProvider);
          if (playbackState.playbackLoadState != LoadState.loading) {
            skipToNext();
          }
        }
      },
      onError: (Object e, StackTrace stackTrace) {
        _handlePlayerError();
      },
    );

    _player.playingStream.listen((playing) {
      _container.read(playbackProvider.notifier).setPlayingState(playing);
    }, onError: (Object e, StackTrace stackTrace) {});

    _player.durationStream.listen((duration) {
      if (duration != null) {
        _container
            .read(playbackProvider.notifier)
            .updateCurrentSongDuration(duration);
      }
    }, onError: (Object e, StackTrace stackTrace) {});

    _player.playerStateStream.listen(
      (playerState) {
        if (playerState.processingState == ProcessingState.idle) {
          _handlePlayerError();
        }
      },
      onError: (Object e, StackTrace stackTrace) {
        _handlePlayerError();
      },
    );

    _initAudioSession();
  }

  void _handlePlayerError() {
    if (_retrying) return;
    final playback = _container.read(playbackProvider);
    final song = playback.currentSong;
    if (song == null || playback.playbackLoadState == LoadState.loading) return;

    _retrying = true;
    _container.read(songCacheProvider.notifier).evictPlaybackInfo(song.id);
    _container
        .read(playbackProvider.notifier)
        .retryCurrentSong()
        .whenComplete(() => _retrying = false);
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  audio.PlaybackState _transformEvent(PlaybackEvent event) {
    final playback = _container.read(playbackProvider);

    return audio.PlaybackState(
      controls: [
        audio.MediaControl.skipToPrevious,
        if (_player.playing)
          audio.MediaControl.pause
        else
          audio.MediaControl.play,
        audio.MediaControl.skipToNext,
        audio.MediaControl.fastForward,
      ],
      systemActions: const {
        audio.MediaAction.seek,
        audio.MediaAction.seekForward,
        audio.MediaAction.seekBackward,
        audio.MediaAction.skipToPrevious,
        audio.MediaAction.skipToNext,
        audio.MediaAction.setShuffleMode,
        audio.MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState:
          const {
            ProcessingState.idle: audio.AudioProcessingState.idle,
            ProcessingState.loading: audio.AudioProcessingState.loading,
            ProcessingState.buffering: audio.AudioProcessingState.buffering,
            ProcessingState.ready: audio.AudioProcessingState.ready,
            ProcessingState.completed: audio.AudioProcessingState.completed,
          }[_player.processingState] ??
          audio.AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      updateTime: DateTime.now(),
      shuffleMode: playback.shuffle
          ? audio.AudioServiceShuffleMode.all
          : audio.AudioServiceShuffleMode.none,
      repeatMode: _mapRepeatMode(playback.repeatMode),
    );
  }

  audio.AudioServiceRepeatMode _mapRepeatMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none:
        return audio.AudioServiceRepeatMode.none;
      case RepeatMode.one:
        return audio.AudioServiceRepeatMode.one;
      case RepeatMode.all:
        return audio.AudioServiceRepeatMode.all;
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _container.read(playbackProvider.notifier).clearStateForStop();
  }

  @override
  Future<void> skipToNext() async {
    await _container.read(playbackProvider.notifier).playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _container.read(playbackProvider.notifier).playPrevious();
  }

  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + const Duration(seconds: 5);

    await _player.seek(newPosition);
  }

  @override
  Future<void> setShuffleMode(audio.AudioServiceShuffleMode shuffleMode) async {
    _container.read(playbackProvider.notifier).toggleShuffle();
  }

  @override
  Future<void> setRepeatMode(audio.AudioServiceRepeatMode repeatMode) async {
    _container.read(playbackProvider.notifier).toggleRepeatMode();
  }

  void updateMetadata(Song song) {
    final metadata = audio.MediaItem(
      id: song.id,
      album: song.album?.title ?? song.title,
      title: song.title,
      artist: song.artists?.map((e) => e.name).join(', ') ?? 'Unknown Artist',
      duration: Duration(seconds: song.duration),
      artUri: song.thumbnail != null && song.thumbnail!.isNotEmpty
          ? Uri.parse(song.thumbnail!)
          : null,
    );
    mediaItem.add(metadata);
  }

  Future<void> playUrl(Song song, String url) async {
    updateMetadata(song);
    _retrying = false;

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));

      final actualDuration = _player.duration;
      final currentMetadata = mediaItem.value;
      if (currentMetadata != null &&
          actualDuration != null &&
          actualDuration != currentMetadata.duration) {
        mediaItem.add(currentMetadata.copyWith(duration: actualDuration));
      }

      if (_container.read(playbackProvider).playing) {
        _player.play();
      }
    } catch (e) {
      final currentSong = _container.read(playbackProvider).currentSong;
      if (currentSong?.id != song.id) {
        return;
      }
      if (!_retrying) {
        _retrying = true;
        _container.read(songCacheProvider.notifier).evictPlaybackInfo(song.id);
        await _container
            .read(playbackProvider.notifier)
            .retryCurrentSong()
            .whenComplete(() => _retrying = false);
      } else {
        playbackState.add(
          playbackState.value.copyWith(errorMessage: e.toString()),
        );
      }
    }
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
}

class SwitchingAudioHandler extends audio.BaseAudioHandler with audio.SeekHandler {
  final PlayerAudioHandler playerHandler;
  final RoomAudioHandler roomHandler;
  bool _useRoom = false;

  SwitchingAudioHandler(this.playerHandler, this.roomHandler) {
    playerHandler.playbackState.listen((state) {
      if (!_useRoom) playbackState.add(state);
    });
    roomHandler.playbackState.listen((state) {
      if (_useRoom) playbackState.add(state);
    });
    playerHandler.mediaItem.listen((item) {
      if (!_useRoom) mediaItem.add(item);
    });
    roomHandler.mediaItem.listen((item) {
      if (_useRoom) mediaItem.add(item);
    });
  }

  bool get useRoom => _useRoom;

  void switchToRoom() {
    if (!_useRoom) {
      _useRoom = true;
      playerHandler.stop();
      playbackState.add(roomHandler.playbackState.value);
      mediaItem.add(roomHandler.mediaItem.value);
    }
  }

  void switchToPlayer() {
    if (_useRoom) {
      _useRoom = false;
      roomHandler.stopLocal();
      playbackState.add(playerHandler.playbackState.value);
      mediaItem.add(playerHandler.mediaItem.value);
    }
  }

  audio.AudioHandler get _activeHandler => _useRoom ? roomHandler : playerHandler;

  @override
  Future<void> play() => _activeHandler.play();

  @override
  Future<void> pause() => _activeHandler.pause();

  @override
  Future<void> seek(Duration position) => _activeHandler.seek(position);

  @override
  Future<void> stop() => _activeHandler.stop();

  @override
  Future<void> skipToNext() => _activeHandler.skipToNext();

  @override
  Future<void> skipToPrevious() => _activeHandler.skipToPrevious();

  @override
  Future<void> fastForward() => _activeHandler.fastForward();

  @override
  Future<void> setShuffleMode(audio.AudioServiceShuffleMode shuffleMode) =>
      _activeHandler.setShuffleMode(shuffleMode);

  @override
  Future<void> setRepeatMode(audio.AudioServiceRepeatMode repeatMode) =>
      _activeHandler.setRepeatMode(repeatMode);
}

class PlayerAudioService {
  static late final SwitchingAudioHandler _switchingHandler;

  static audio.AudioHandler get handler => _switchingHandler;
  static PlayerAudioHandler get vibezHandler => _switchingHandler.playerHandler;
  static RoomAudioHandler get roomHandler => _switchingHandler.roomHandler;

  static void switchToRoom() => _switchingHandler.switchToRoom();
  static void switchToPlayer() => _switchingHandler.switchToPlayer();

  static Future<void> init(ProviderContainer container) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final justAudioCacheDir = Directory(
        '${tempDir.path}/just_audio_cache/remote',
      );
      if (!await justAudioCacheDir.exists()) {
        await justAudioCacheDir.create(recursive: true);
      }
    } catch (_) {}

    final playerHandler = PlayerAudioHandler(container);
    final roomHandler = RoomAudioHandler(container);
    final switching = SwitchingAudioHandler(playerHandler, roomHandler);

    _switchingHandler = await audio.AudioService.init(
      builder: () => switching,
      config: const audio.AudioServiceConfig(
        androidNotificationChannelId: 'com.aryan.vibez.channel.audio',
        androidNotificationChannelName: 'Vibez Music Playback',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        preloadArtwork: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/app_icon',
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );
  }
}
