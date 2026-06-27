import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/provider/room_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';

class RoomAudioHandler extends audio.BaseAudioHandler with audio.SeekHandler {
  final ProviderContainer _container;
  final AudioPlayer _player = AudioPlayer();

  RoomAudioHandler(this._container) {
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
          final roomId = _container.read(activeRoomIdProvider);
          if (roomId != null) {
            final roomState = _container.read(roomProvider(roomId));
            final userId = _container.read(userProvider)?.id;
            final isDj = roomState.room?.currentDj?.id == userId;
            if (isDj) {
              skipToNext();
            }
          }
        }
      },
      onError: (Object e, StackTrace stackTrace) {
        _handlePlayerError();
      },
    );

    _initAudioSession();
  }

  void _handlePlayerError() {}

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  audio.PlaybackState _transformEvent(PlaybackEvent event) {
    return audio.PlaybackState(
      controls: const [],
      systemActions: const {},
      androidCompactActionIndices: const [],
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
    );
  }

  @override
  Future<void> play() async {
    final roomId = _container.read(activeRoomIdProvider);
    if (roomId != null) {
      final roomState = _container.read(roomProvider(roomId));
      final room = roomState.room;
      if (room != null && room.playing && room.startedAt != null) {
        final elapsed = DateTime.now().difference(room.startedAt!);
        final duration = Duration(seconds: room.currentSong?.duration ?? 0);
        if (elapsed < duration) {
          await _player.seek(elapsed);
        }
      }
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stopLocal() async {
    await _player.stop();
  }

  @override
  Future<void> stop() async {
    final roomId = _container.read(activeRoomIdProvider);
    if (roomId != null) {
      final roomState = _container.read(roomProvider(roomId));
      final userId = _container.read(userProvider)?.id;
      final isDj = roomState.room?.currentDj?.id == userId;
      if (isDj) {
        await roomState.stop();
      }
    }
    await stopLocal();
  }

  @override
  Future<void> skipToNext() async {
    final roomId = _container.read(activeRoomIdProvider);
    if (roomId == null) return;
    final roomState = _container.read(roomProvider(roomId));
    final userId = _container.read(userProvider)?.id;
    final isDj = roomState.room?.currentDj?.id == userId;
    if (isDj) {
      await roomState.playNext();
    }
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

  Future<void> playUrl(
    Song song,
    String url,
    DateTime? startedAt,
    Duration serverTimeOffset,
    bool shouldPlay,
  ) async {
    updateMetadata(song);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      
      Duration seekPos = Duration.zero;
      if (startedAt != null) {
        final serverTime = DateTime.now().add(serverTimeOffset);
        seekPos = serverTime.difference(startedAt);
      }
      
      final duration = Duration(seconds: song.duration);
      final finalSeek = seekPos < duration ? seekPos : Duration.zero;
      await _player.seek(finalSeek);
      if (shouldPlay) {
        await _player.play();
      } else {
        await _player.pause();
      }
    } catch (e) {
      final roomId = _container.read(activeRoomIdProvider);
      if (roomId == null) return;
      final roomState = _container.read(roomProvider(roomId));
      if (roomState.room?.currentSong?.id != song.id) return;

      playbackState.add(
        playbackState.value.copyWith(errorMessage: e.toString()),
      );
    }
  }

  Duration get position => _player.position;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<bool> get playingStream => _player.playingStream;
}
