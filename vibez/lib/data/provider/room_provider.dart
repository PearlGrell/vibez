import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vibez/core/network/socket_client.dart';
import 'package:vibez/data/models/queue_item.dart';
import 'package:vibez/data/models/request_item.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/models/room_state.dart';
import 'package:vibez/data/models/song.dart';
import 'package:vibez/data/models/user.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/song_cache_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';

enum RoomStatus { loading, ready, error }

final roomProvider = ChangeNotifierProvider.autoDispose
    .family<RoomProvider, String>((ref, roomId) {
      return RoomProvider(ref, roomId);
    });

final activeRoomIdProvider = StateProvider<String?>((ref) => null);

enum RecommendationState { initial, loading, success, error }

class RoomProvider extends ChangeNotifier {
  final Ref _ref;
  final String roomId;
  final SocketClient _socket = SocketClient.instance;
  StreamSubscription? _sub;
  StreamSubscription? _globalSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _requestSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _djRequestsSub;

  final StreamController<RequestItem> _songRequestedController =
      StreamController<RequestItem>.broadcast();
  final StreamController<User> _djRequestedController =
      StreamController<User>.broadcast();

  Stream<RequestItem> get onSongRequested => _songRequestedController.stream;
  Stream<User> get onDjRequested => _djRequestedController.stream;

  bool _disposed = false;

  RoomStatus status = RoomStatus.loading;
  Room? room;
  int participants = 0;
  List<String> participantsInitials = [];
  List<QueueItem> queue = [];
  List<RequestItem> requestItems = [];
  List<User> djRequests = [];
  List<Song> recommendations = [];
  bool isInRoom = false;
  Object? error;

  RecommendationState recommendationState = .initial;
  Song? _lastSong;

  RoomProvider(this._ref, this.roomId) {
    _init();
  }

  Future<void> _maybeFetchRecommendations() async {
    final currentSong = room?.currentSong;
    if (currentSong == null || currentSong.id == _lastSong?.id) return;

    recommendationState = RecommendationState.loading;
    recommendations.clear();
    notifyListeners();

    try {
      final res = await _ref
          .read(songCacheProvider.notifier)
          .fetchRelated(currentSong.id);
      recommendations = res ?? [];
      recommendationState = RecommendationState.success;
      _lastSong = currentSong;
    } catch (e) {
      recommendationState = RecommendationState.error;
    }
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      final response = await _socket.emitWithAck('room:details', {
        'roomId': roomId,
      });
      final state = RoomState.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      room = state.room;
      participants = state.participants;
      participantsInitials = state.participantsInitials;

      final userId = _ref.read(userProvider)?.id;
      isInRoom = userId != null && room?.currentDj?.id == userId;
      status = RoomStatus.ready;
      notifyListeners();

      _fetchQueue();
      _maybeFetchRecommendations();

      _sub = _socket.stream('room:state_update').listen((data) {
        final update = RoomState.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        if (update.room.id != roomId) return;
        final previousDjId = room?.currentDj?.id;
        room = update.room;
        participants = update.participants;
        participantsInitials = update.participantsInitials;
        if (room?.currentDj != null && room?.currentDj?.id != previousDjId) {
          djRequests.clear();
        }
        notifyListeners();
        _maybeFetchRecommendations();
      });

      _queueSub = _socket.stream('room:queue_update').listen((data) async {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['roomId'] != roomId) return;
        queue =
            (map['queue'] as List?)
                ?.map(
                  (e) =>
                      QueueItem.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList() ??
            [];
        notifyListeners();
      });

      _requestSub = _socket.stream('room:song_requested').listen((data) async {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['roomId'] != roomId) return;
        final item = RequestItem.fromJson(map);
        requestItems.add(item);
        _songRequestedController.add(item);
        notifyListeners();
      });

      _djRequestsSub = _socket.stream('room:dj_requested').listen((data) async {
        final map = Map<String, dynamic>.from(data as Map);
        final user = User.fromJson(
          Map<String, dynamic>.from(map['user'] as Map),
        );
        if (djRequests.any((u) => u.id == user.id)) return;
        djRequests.add(user);
        _djRequestedController.add(user);
        notifyListeners();
      });

      _connectionSub = _socket.connectionStream().listen((connected) {
        if (connected && isInRoom) {
          _rejoinRoom();
        }
      });

      _globalSub = _socket.stream('rooms:update').listen((data) {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['id'] != roomId) return;
        room = Room.fromJson(map);
        participants = map['participants'] as int? ?? participants;
        if (map['participantsInitials'] != null) {
          participantsInitials = List<String>.from(
            map['participantsInitials'] as List,
          );
        }
        notifyListeners();
        _maybeFetchRecommendations();
      });
    } catch (e) {
      error = e;
      status = RoomStatus.error;
      notifyListeners();
    }
  }

  Future<void> _rejoinRoom() async {
    try {
      await _socket.emitWithAck('room:join', {'roomId': roomId});
      final userId = _ref.read(userProvider)?.id;
      if (room?.currentDj?.id == userId) {
        await _socket.emitWithAck('room:join_dj', {'roomId': roomId});
      }
      await refresh();
      await _fetchQueue();
    } catch (_) {}
  }

  Future<void> _fetchQueue() async {
    try {
      final response = await _socket.emitWithAck('room:queue', {
        'roomId': roomId,
      });
      final data = Map<String, dynamic>.from(response as Map);
      queue =
          (data['queue'] as List?)
              ?.map(
                (e) => QueueItem.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addSong(String songId) async {
    if (room?.currentSong == null) {
      await songChanged(songId);
    } else {
      await _socket.emitWithAck('room:add_song', {
        'roomId': roomId,
        'songId': songId,
      });
    }
  }

  Future<void> requestSong(String songId) async {
    await _socket.emitWithAck('room:request_song', {
      'roomId': roomId,
      'songId': songId,
    });
  }

  Future<void> requestDj() async {
    await _socket.emitWithAck('room:request_dj', {'roomId': roomId});
  }

  Future<void> songChanged(String songId) async {
    await _socket.emitWithAck('room:song_changed', {
      'roomId': roomId,
      'songId': songId,
    });
  }

  Future<void> removeRecommendation(String songId) async {
    recommendations.removeWhere((song) => song.id == songId);
    notifyListeners();
  }

  Future<void> acceptRequest(
    String songId,
    String requestedById,
    DateTime addedAt,
  ) async {
    await _socket.emitWithAck('room:add_song', {
      'roomId': roomId,
      'songId': songId,
      'requestedById': requestedById,
    });
    _removeRequest(songId, requestedById, addedAt);
  }

  void rejectRequest(String songId, String userId, DateTime addedAt) async {
    _removeRequest(songId, userId, addedAt);
  }

  void _removeRequest(String songId, String userId, DateTime addedAt) {
    requestItems.removeWhere(
      (item) =>
          item.requestedBy.id == userId &&
          item.song.id == songId &&
          item.addedAt == addedAt,
    );
    notifyListeners();
  }

  Future<void> acceptDjRequest(String userId) async {
    await _socket.emitWithAck('room:assign_dj', {
      'roomId': roomId,
      'userId': userId,
    });
    _removeDjRequest(userId);
  }

  void rejectDjRequest(String userId) {
    _removeDjRequest(userId);
  }

  void _removeDjRequest(String userId) {
    djRequests.removeWhere((user) => user.id == userId);
    notifyListeners();
  }

  Future<void> playNext() async {
    if (queue.isEmpty) return;
    final queueItem = queue.first;
    await Future.wait([
      songChanged(queueItem.song.id),
      removeSong(queueItem.id),
    ]);
  }

  Future<void> playItem(QueueItem queueItem) async {
    await Future.wait([
      songChanged(queueItem.song.id),
      removeSong(queueItem.id),
    ]);
  }

  Future<void> stop() async {
    try {
      await _socket.emitWithAck('room:stop', {'roomId': roomId});
    } catch (e) {
      debugPrint("Error emitting room:stop: $e");
    }
  }

  Future<void> removeSong(String queueItemId) async {
    await _socket.emitWithAck('room:remove_song', {
      'roomId': roomId,
      'queueItemId': queueItemId,
    });
  }

  Future<void> joinRoom() async {
    _ref.read(playbackProvider.notifier).stopAndClear();
    _ref.read(playbackProvider.notifier).clearQueue();

    await _socket.emitWithAck('room:join', {'roomId': roomId});
    if (room?.currentDj == null) {
      await _socket.emitWithAck('room:join_dj', {'roomId': roomId});
    }
    isInRoom = true;
    _ref.read(activeRoomIdProvider.notifier).state = roomId;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    final userId = _ref.read(userProvider)?.id;
    if (room?.currentDj?.id == userId) {
      await stop();
      await _socket.emitWithAck('room:leave_dj', {'roomId': roomId});
    }
    await _socket.emitWithAck('room:leave', {'roomId': roomId});
    isInRoom = false;
    _ref.read(activeRoomIdProvider.notifier).state = null;
    notifyListeners();
  }

  Future<void> leaveDj() async {
    await _socket.emitWithAck('room:leave_dj', {'roomId': roomId});
  }

  Future<void> toggleFollow() async {
    if (room == null) return;

    final userNotifier = _ref.read(userProvider.notifier);
    final user = _ref.read(userProvider);
    final isFollowing =
        user?.joinedRooms?.any((e) => e.id == room!.id) ?? false;

    if (isFollowing) {
      await userNotifier.unfollowRoom(room!.id);
    } else {
      await userNotifier.followRoom(room!);
    }
  }

  Future<void> refresh() async {
    try {
      final response = await _socket.emitWithAck('room:details', {
        'roomId': roomId,
      });
      final state = RoomState.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      room = state.room;
      participants = state.participants;
      participantsInitials = state.participantsInitials;
      status = RoomStatus.ready;
      error = null;
      notifyListeners();
      _maybeFetchRecommendations();
    } catch (e) {
      error = e;
      status = RoomStatus.error;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _globalSub?.cancel();
    _queueSub?.cancel();
    _requestSub?.cancel();
    _djRequestsSub?.cancel();
    _connectionSub?.cancel();
    _songRequestedController.close();
    _djRequestedController.close();
    super.dispose();
  }
}
