import 'package:vibez/core/network/api_client.dart';

class SearchService {
  static final SearchService instance = SearchService._();
  late final ApiClient _apiClient;

  SearchService._() {
    _apiClient = ApiClient.instance;
  }

  Future<Map<String, dynamic>> search(
    String query, {
    String? filter,
    int limit = 20,
  }) async {
    final Map<String, dynamic> queries = {
      'q': query,
      'limit': limit.toString(),
    };
    if (filter != null) {
      queries['filter'] = filter;
    }
    return _apiClient.get(
      endpoint: '/search',
      queries: queries,
    );
  }
}
