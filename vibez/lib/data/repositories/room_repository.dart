import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/services/room_service.dart';

class RoomRepository {
  static final RoomRepository instance = RoomRepository._();
  late final RoomService _roomService;
  final Map<String, Room> _roomCache = {};

  RoomRepository._() {
    _roomService = RoomService.instance;
  }

  Future<Room?> getRoom(String id) async {
    if (_roomCache.containsKey(id)) {
      return _roomCache[id];
    }
    try {
      final res = await _roomService.getRoom(id);
      final room = Room.fromJson(res);
      _roomCache[id] = room;
      return room;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  void invalidateCache(String id) {
    _roomCache.remove(id);
  }

  Future<Room?> createRoom({
    required String name,
    required bool private,
    required List<String> tags,
    String? description,
  }) async {
    try {
      final res = await _roomService.createRoom(
        name: name,
        private: private,
        tags: tags,
        description: description,
      );
      final room = Room.fromJson(res);
      _roomCache[room.id] = room;
      return room;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }

  Future<Room?> updateRoom({
    required String id,
    String? name,
    bool? private,
    List<String>? tags,
    String? description,
  }) async {
    try {
      final res = await _roomService.updateRoom(
        id: id,
        name: name,
        private: private,
        tags: tags,
        description: description,
      );
      final room = Room.fromJson(res);
      _roomCache[room.id] = room;
      return room;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }
}
