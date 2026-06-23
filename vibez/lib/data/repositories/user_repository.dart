import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_logger.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/user.dart';
import 'package:vibez/data/services/user_service.dart';

class UserRepository {
  static final UserRepository instance = UserRepository._();
  late final UserService _userService;

  UserRepository._() {
    _userService = UserService.instance;
  }

  Future<User?> me() async {
    try {
      final res = await _userService.getMe();
      final currentUser = User.fromJson(res);
      return currentUser;
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppLogger.instance.error(errorMessage, error: err);
      return null;
    }
  }

  Future<User?> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _userService.updateMe(id, data);
      return User.fromJson(res);
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppLogger.instance.error(errorMessage, error: err);
      return null;
    }
  }

  Future<bool> checkUsername(String username) async {
    try {
      final res = await _userService.checkUsername(username);
      return res['available'] == true;
    } catch (err) {
      return false;
    }
  }

  Future<bool> likeSong(String songId) async {
    try {
      final res = await _userService.likeSong(songId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> unlikeSong(String songId) async {
    try {
      final res = await _userService.unlikeSong(songId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> likeAlbum(String albumId) async {
    try {
      final res = await _userService.likeAlbum(albumId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> unlikeAlbum(String albumId) async {
    try {
      final res = await _userService.unlikeAlbum(albumId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> likePlaylist(String playlistId) async {
    try {
      final res = await _userService.likePlaylist(playlistId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> unlikePlaylist(String playlistId) async {
    try {
      final res = await _userService.unlikePlaylist(playlistId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> followArtist(String artistId) async {
    try {
      final res = await _userService.followArtist(artistId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<bool> unfollowArtist(String artistId) async {
    try {
      final res = await _userService.unfollowArtist(artistId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: .error);
      return false;
    }
  }

  Future<User?> getUser(String id) async {
    try {
      final res = await _userService.getUser(id);
      return User.fromJson(res);
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppLogger.instance.error(errorMessage, error: err);
      return null;
    }
  }

  Future<bool> followUser(String id) async {
    try {
      final res = await _userService.followUser(id);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: AppSnackType.error);
      return false;
    }
  }

  Future<bool> unfollowUser(String id) async {
    try {
      final res = await _userService.unfollowUser(id);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: AppSnackType.error);
      return false;
    }
  }

  Future<bool> followRoom(String roomId) async {
    try {
      final res = await _userService.followRoom(roomId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: AppSnackType.error);
      return false;
    }
  }

  Future<bool> unfollowRoom(String roomId) async {
    try {
      final res = await _userService.unfollowRoom(roomId);
      return res['success'] == true;
    } catch (err) {
      AppSnackbar.show(message: "Something went wrong.", type: AppSnackType.error);
      return false;
    }
  }
}
