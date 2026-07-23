import 'package:vibez/core/network/api_client.dart';

class RoomService {
  static final RoomService instance = RoomService._();
  late ApiClient _apiClient;

  RoomService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> getRoom(String id) async {
    return await _apiClient.get(endpoint: '/rooms/$id', secure: true);
  }

  Future<Map<String, dynamic>> getRooms({
    int? limit,
    int? page,
    String? sort,
  }) async {
    return await _apiClient.get(
      endpoint: '/rooms',
      queries: {
        'limit': ?limit,
        'page': ?page,
        'sort': ?sort,
      },
      secure: true,
    );
  }

  Future<List<dynamic>> getMyRooms() async {
    return await _apiClient.get(endpoint: '/rooms/me', secure: true);
  }

  Future<List<dynamic>> getUserRooms(String id) async {
    return await _apiClient.get(endpoint: '/rooms/user/$id', secure: true);
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    required bool private,
    required List<String> tags,
    String? description,
  }) async {
    return await _apiClient.post(
      endpoint: '/rooms',
      body: {
        'name': name,
        'private': private,
        'tags': tags,
        'description': description,
      },
      secure: true,
    );
  }

  Future<Map<String, dynamic>> updateRoom({
    required String id,
    String? name,
    bool? private,
    List<String>? tags,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (private != null) body['private'] = private;
    if (tags != null) body['tags'] = tags;
    if (description != null) body['description'] = description;

    return await _apiClient.patch(
      endpoint: '/rooms/$id',
      body: body,
      secure: true,
    );
  }

  Future<Map<String, dynamic>> deleteRoom({required String id}) async {
    return await _apiClient.delete(
      endpoint: '/rooms/$id',
      secure: true,
    );
  }
}
