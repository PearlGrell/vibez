import 'package:vibez/core/network/api_client.dart';

class AlbumService {
  static final AlbumService instance = AlbumService._();
  late ApiClient _apiClient;

  AlbumService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> getAlbum(String id) async {
    return await _apiClient.get(endpoint: '/albums/$id');
  }
}
