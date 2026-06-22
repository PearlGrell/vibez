import 'package:vibez/core/network/api_client.dart';

class ArtistService {
  static final ArtistService instance = ArtistService._();
  late ApiClient _apiClient;

  ArtistService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> getArtist(String id) async {
    return await _apiClient.get(endpoint: '/artists/$id');
  }

  Future<Map<String, dynamic>> getArtistSongs(String id, String browseId) async {
    return await _apiClient.get(
      endpoint: '/artists/$id/songs',
      queries: {'browseId': browseId},
    );
  }

  Future<Map<String, dynamic>> getArtistAlbums(
    String id, {
    String? browseId,
    String? params,
  }) async {
    final Map<String, dynamic> queries = {};
    if (browseId != null && browseId.isNotEmpty) queries['browseId'] = browseId;
    if (params != null && params.isNotEmpty) queries['params'] = params;
    return await _apiClient.get(
      endpoint: '/artists/$id/albums',
      queries: queries,
    );
  }
}
