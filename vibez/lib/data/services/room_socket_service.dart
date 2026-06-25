import 'dart:async';

import 'package:vibez/core/network/socket_client.dart';
import 'package:vibez/data/models/room_state.dart';

class RoomSocketService {
  final SocketClient _socketClient;
  final StreamController<RoomState> _stateController =
      StreamController<RoomState>.broadcast();
  StreamSubscription? _serverSubscription;

  RoomSocketService(this._socketClient) {
    _serverSubscription = _socketClient.stream('room:state_update').listen((data) {
      final mapData = Map<String, dynamic>.from(data as Map);
      _stateController.add(RoomState.fromJson(mapData));
    });
  }

  RoomState _parseResponse(dynamic response) {
    final data = Map<String, dynamic>.from(response as Map);
    return RoomState.fromJson(data);
  }

  Future<RoomState> getRoomDetails(String roomId) async {
    final response = await _socketClient.emitWithAck('room:details', {'roomId': roomId});
    return _parseResponse(response);
  }

  Stream<RoomState> get roomStateUpdates => _stateController.stream;

  Future<RoomState> joinRoom(String roomId) async {
    final response = await _socketClient.emitWithAck('room:join', {'roomId': roomId});
    final result = _parseResponse(response);
    _stateController.add(result);
    return result;
  }

  Future<void> leaveRoom(String roomId) async {
    await _socketClient.emitWithAck('room:leave', {'roomId': roomId});
    final result = await getRoomDetails(roomId);
    _stateController.add(result);
  }

  Future<RoomState> joinAsDJ(String roomId) async {
    final response = await _socketClient.emitWithAck('room:join_dj', {'roomId': roomId});
    final result = _parseResponse(response);
    _stateController.add(result);
    return result;
  }

  Future<RoomState> leaveAsDJ(String roomId) async {
    final response = await _socketClient.emitWithAck('room:leave_dj', {'roomId': roomId});
    final result = _parseResponse(response);
    _stateController.add(result);
    return result;
  }

  void dispose() {
    _serverSubscription?.cancel();
    _stateController.close();
  }
}
