import 'package:vibez/core/network/api_client.dart';

class UserService {
  static final UserService instance = UserService._();
  late final ApiClient _apiClient;

  UserService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> getMe() async {
    return _apiClient.get(endpoint: '/users/me', secure: true);
  }

  Future<Map<String, dynamic>> updateMe(String id, Map<String, dynamic> data) async {
    return _apiClient.patch(endpoint: '/users/$id', body: data, secure: true);
  }

  Future<Map<String, dynamic>> checkUsername(String username) {
    return _apiClient.get(
      endpoint: '/users/check-username',
      queries: {'username': username},
    );
  }

  Future<Map<String, dynamic>> likeSong(String songId) {
    return _apiClient.post(
      endpoint: '/users/liked-songs/$songId',
      secure: true
    );
  }

  Future<Map<String, dynamic>> unlikeSong(String songId) {
    return _apiClient.delete(
      endpoint: '/users/liked-songs/$songId',
      secure: true
    );
  }

  Future<Map<String, dynamic>> likeAlbum(String albumId) {
    return _apiClient.post(
      endpoint: '/users/liked-albums/$albumId',
      secure: true,
    );
  }

  Future<Map<String, dynamic>> unlikeAlbum(String albumId) {
    return _apiClient.delete(
      endpoint: '/users/liked-albums/$albumId',
      secure: true,
    );
  }

  Future<Map<String, dynamic>> likePlaylist(String playlistId) {
    return _apiClient.post(
      endpoint: '/users/liked-playlists/$playlistId',
      secure: true,
    );
  }

  Future<Map<String, dynamic>> unlikePlaylist(String playlistId) {
    return _apiClient.delete(
      endpoint: '/users/liked-playlists/$playlistId',
      secure: true,
    );
  }

  Future<Map<String, dynamic>> followArtist(String artistId) {
    return _apiClient.post(
      endpoint: '/users/followed-artists/$artistId',
      secure: true,
    );
  }

  Future<Map<String, dynamic>> unfollowArtist(String artistId) {
    return _apiClient.delete(
      endpoint: '/users/followed-artists/$artistId',
      secure: true,
    );
  }
}
