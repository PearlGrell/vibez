

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/provider/playback_provider.dart';
import 'package:vibez/data/services/room_socket_service.dart';

final roomSocketServiceProvider = Provider<RoomSocketService>((ref) {
  final service = RoomSocketService(SocketClient.instance);
  ref.onDispose(service.dispose);
  return service;
});

final roomProvider = AsyncNotifierProvider.autoDispose
    .family<RoomNotifier, RoomViewState, String>(RoomNotifier.new);

class RoomViewState {
  final Room room;
  final int participants;
  final List<String> participantsInitials;
  final bool isInRoom;

  const RoomViewState({
    required this.room,
    required this.participants,
    required this.participantsInitials,
    required this.isInRoom,
  });

  RoomViewState copyWith({
    Room? room,
    int? participants,
    List<String>? participantsInitials,
    bool? isInRoom,
  }) {
    return RoomViewState(
      room: room ?? this.room,
      participants: participants ?? this.participants,
      participantsInitials: participantsInitials ?? this.participantsInitials,
      isInRoom: isInRoom ?? this.isInRoom,
    );
  }
}

class RoomNotifier
    extends AutoDisposeFamilyAsyncNotifier<RoomViewState, String> {
  StreamSubscription? _sub;

  @override
  Future<RoomViewState> build(String roomId) async {
    ref.onDispose(() {
      _sub?.cancel();
      ref.read(roomSocketServiceProvider).leaveRoom(roomId);
    });

    ref.read(playbackProvider.notifier).pause();
    ref.read(playbackProvider.notifier).clearQueue();

    final service = ref.read(roomSocketServiceProvider);
    final initial = await service.getRoomDetails(roomId);

    _sub?.cancel();
    _sub = service.roomStateUpdates.listen((update) {
      final current = state.valueOrNull;
      if (current == null) return;
      state = AsyncData(current.copyWith(
        room: update.room,
        participants: update.participants,
        participantsInitials: update.participantsInitials,
      ));
    });

    final userId = ref.read(userProvider)?.id;
    final isInRoom =
        userId != null && initial.room.currentDj?.id == userId;

    return RoomViewState(
      room: initial.room,
      participants: initial.participants,
      participantsInitials: initial.participantsInitials,
      isInRoom: isInRoom,
    );
  }

  Future<void> joinRoom() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final service = ref.read(roomSocketServiceProvider);
    await service.joinRoom(arg);
    if (current.room.currentDj == null) {
      await service.joinAsDJ(arg);
    }
    state = AsyncData(current.copyWith(isInRoom: true));
  }

  Future<void> leaveRoom() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final service = ref.read(roomSocketServiceProvider);
    final userId = ref.read(userProvider)?.id;
    if (current.room.currentDj?.id == userId) {
      await service.leaveAsDJ(arg);
    }
    await service.leaveRoom(arg);
    state = AsyncData(current.copyWith(isInRoom: false));
  }

  Future<void> leaveDj() async {
    await ref.read(roomSocketServiceProvider).leaveAsDJ(arg);
  }

  Future<void> toggleFollow() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final userNotifier = ref.read(userProvider.notifier);
    final user = ref.read(userProvider);
    final isFollowing =
        user?.joinedRooms?.any((e) => e.id == current.room.id) ?? false;

    if (isFollowing) {
      await userNotifier.unfollowRoom(current.room.id);
    } else {
      await userNotifier.followRoom(current.room);
    }
  }

  Future<void> refresh() async {
    final service = ref.read(roomSocketServiceProvider);
    final updated = await service.getRoomDetails(arg);
    final current = state.valueOrNull;
    state = AsyncData(RoomViewState(
      room: updated.room,
      participants: updated.participants,
      participantsInitials: updated.participantsInitials,
      isInRoom: current?.isInRoom ?? false,
    ));
  }
}
