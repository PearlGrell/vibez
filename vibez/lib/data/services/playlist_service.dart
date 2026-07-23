import 'package:vibez/core/network/api_client.dart';

class PlaylistService {
  static final PlaylistService instance = PlaylistService._();
  late ApiClient _apiClient;

  PlaylistService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> getPlaylist(String id) async {
    return await _apiClient.get(endpoint: '/users/playlists/$id', secure: true);
  }

  Future<List<dynamic>> getPlaylists({int? limit}) async {
    return await _apiClient.get(
      endpoint: '/users/playlists',
      queries: {'limit': ?limit},
      secure: true,
    );
  }

  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    required bool private,
    required List<String> tags,
    required String createdById,
    String? thumbnail,
    String? description,
  }) async {
    return await _apiClient.post(
      endpoint: '/users/playlists',
      body: {
        'name': name,
        'private': private,
        'tags': tags,
        'createdById': createdById,
        'thumbnail': thumbnail,
        'description': description,
      },
      secure: true,
    );
  }

  Future<Map<String, dynamic>> updatePlaylist({
    required String id,
    String? name,
    bool? private,
    List<String>? tags,
    String? thumbnail,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (private != null) body['private'] = private;
    if (tags != null) body['tags'] = tags;
    if (thumbnail != null) body['thumbnail'] = thumbnail;
    if (description != null) body['description'] = description;

    return await _apiClient.post(
      endpoint: '/users/playlists/$id',
      body: body,
      secure: true,
    );
  }

  Future<Map<String, dynamic>> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    return await _apiClient.post(
      endpoint: '/users/playlists/$playlistId/songs',
      body: {
        'songId': songId,
      },
      secure: true,
    );
  }
}
