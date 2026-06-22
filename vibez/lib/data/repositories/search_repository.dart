import 'package:dio/dio.dart';
import 'package:vibez/core/network/dio_exception_handler.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/services/search_service.dart';

enum SearchFilter {
  all,
  song,
  artist,
  album,
}

class SearchRepository {
  static final SearchRepository instance = SearchRepository._();
  late final SearchService _searchService;

  SearchRepository._() {
    _searchService = SearchService.instance;
  }

  Future<SearchResult?> search(
    String query, {
    SearchFilter filter = SearchFilter.all,
    int limit = 20,
  }) async {
    try {
      final String? filterStr = filter == SearchFilter.all ? null : filter.name;
      final res = await _searchService.search(query, filter: filterStr, limit: limit);
      return SearchResult.fromJson(res);
    } on DioException catch (err) {
      String errorMessage = DioExceptionHandler.getMessage(err);
      AppSnackbar.show(message: errorMessage, type: AppSnackType.error);
      return null;
    }
  }
}
