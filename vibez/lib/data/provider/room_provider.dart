import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vibez/core/network/socket_client.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/models/room_state.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/provider/user_provider.dart';

enum RoomStatus { loading, ready, error }

final roomProvider = ChangeNotifierProvider.autoDispose
    .family<RoomProvider, String>((ref, roomId) {
  return RoomProvider(ref, roomId);
});

class RoomProvider extends ChangeNotifier {
  final Ref _ref;
  final String roomId;
  final SocketClient _socket = SocketClient.instance;
  StreamSubscription? _sub;

  RoomStatus status = RoomStatus.loading;
  Room? room;
  int participants = 0;
  List<String> participantsInitials = [];
  bool isInRoom = false;
  Object? error;

  RoomProvider(this._ref, this.roomId) {
    _init();
  }

  Future<void> _init() async {
    try {
      final response =
          await _socket.emitWithAck('room:details', {'roomId': roomId});
      final state =
          RoomState.fromJson(Map<String, dynamic>.from(response as Map));

      room = state.room;
      participants = state.participants;
      participantsInitials = state.participantsInitials;

      final userId = _ref.read(userProvider)?.id;
      isInRoom = userId != null && room?.currentDj?.id == userId;
      status = RoomStatus.ready;
      notifyListeners();

      _sub = _socket.stream('room:state_update').listen((data) {
        final update =
            RoomState.fromJson(Map<String, dynamic>.from(data as Map));
        room = update.room;
        participants = update.participants;
        participantsInitials = update.participantsInitials;
        notifyListeners();
      });
    } catch (e) {
      error = e;
      status = RoomStatus.error;
      notifyListeners();
    }
  }

  Future<void> joinRoom() async {
    _ref.read(playbackProvider.notifier).pause();
    _ref.read(playbackProvider.notifier).clearQueue();

    await _socket.emitWithAck('room:join', {'roomId': roomId});
    if (room?.currentDj == null) {
      await _socket.emitWithAck('room:join_dj', {'roomId': roomId});
    }
    isInRoom = true;
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    final userId = _ref.read(userProvider)?.id;
    if (room?.currentDj?.id == userId) {
      await _socket.emitWithAck('room:leave_dj', {'roomId': roomId});
    }
    await _socket.emitWithAck('room:leave', {'roomId': roomId});
    isInRoom = false;
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
      final response =
          await _socket.emitWithAck('room:details', {'roomId': roomId});
      final state =
          RoomState.fromJson(Map<String, dynamic>.from(response as Map));

      room = state.room;
      participants = state.participants;
      participantsInitials = state.participantsInitials;
      status = RoomStatus.ready;
      error = null;
      notifyListeners();
    } catch (e) {
      error = e;
      status = RoomStatus.error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _socket.emit('room:leave', {'roomId': roomId});
    super.dispose();
  }
}
