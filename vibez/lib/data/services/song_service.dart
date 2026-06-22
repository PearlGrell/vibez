import 'package:vibez/core/network/api_client.dart';

class SongService {
  static final SongService instance = SongService._();
  late ApiClient _apiClient;

  SongService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String,dynamic>> getSong(String songId) async {
    return await _apiClient.get(endpoint: '/songs/$songId');
  }

  Future<Map<String, dynamic>> getPlaybackUrl(String songId) async {
    return await _apiClient.get(endpoint: '/songs/$songId/play');
  }

  Future<Map<String, dynamic>> getLyrics(String songId) async {
    return await _apiClient.get(endpoint: '/songs/$songId/lyrics');
  }

  Future<Map<String, dynamic>> getRelated(String songId) async {
    return await _apiClient.get(endpoint: '/songs/$songId/related');
  }

  Future<Map<String, dynamic>> getCredits(String songId) async {
    return await _apiClient.get(endpoint: '/songs/$songId/credits');
  }
}