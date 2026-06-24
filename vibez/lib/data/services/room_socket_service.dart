import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/network/socket_client.dart';
import 'package:vibez/data/models/room.dart';

/// Provider for [RoomSocketService] to allow dependency injection and easy mocking.
final roomSocketServiceProvider = Provider<RoomSocketService>((ref) {
  return RoomSocketService(SocketClient.instance);
});

class RoomSocketService {
  final SocketClient _socketClient;

  // Use dependency injection for better testability instead of a hardcoded singleton
  RoomSocketService(this._socketClient);

  /// Gets full details for a single room.
  /// Returns a record containing the strongly-typed [Room] and the current participant count.
  Future<({Room room, int participants})> getRoomDetails(String roomId) async {
    final response = await _socketClient.emitWithAck('room:details', {'roomId': roomId});
    final data = Map<String, dynamic>.from(response as Map);
    
    return (
      room: Room.fromJson(data['room'] as Map<String, dynamic>),
      participants: data['participants'] as int,
    );
  }

  /// Listens to room state changes (DJ join/leave/assign, play/pause, song change).
  /// Returns a stream of records containing the updated strongly-typed [Room] and the participant count.
  Stream<({Room room, int participants})> get roomStateUpdates {
    return _socketClient.stream('room:state_update').map((data) {
      final mapData = Map<String, dynamic>.from(data as Map);
      return (
        room: Room.fromJson(mapData['room'] as Map<String, dynamic>),
        participants: mapData['participants'] as int,
      );
    });
  }
}
