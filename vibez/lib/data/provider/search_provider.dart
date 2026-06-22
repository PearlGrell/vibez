import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/data/models/search_result.dart';
import 'package:vibez/data/repositories/search_repository.dart';

class _CacheEntry {
  final SearchResult result;
  final DateTime timestamp;
  _CacheEntry(this.result) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp).inSeconds > 60;
}

class SearchState {
  final String query;
  final SearchFilter filter;
  final SearchResult? result;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final int currentLimit;

  const SearchState({
    this.query = '',
    this.filter = SearchFilter.all,
    this.result,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.currentLimit = 20,
  });

  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    SearchResult? result,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    int? currentLimit,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      result: clearResult ? null : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentLimit: currentLimit ?? this.currentLimit,
    );
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;
  static const int _pageSize = 20;
  static const int _maxCacheSize = 50;
  final Map<String, _CacheEntry> _cache = {};

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const SearchState();
  }

  void onQueryChanged(String query) {
    if (state.query == query) return;

    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        isLoading: false,
        clearError: true,
        clearResult: true,
        currentLimit: _pageSize,
        hasMore: true,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      clearError: true,
      currentLimit: _pageSize,
      hasMore: true,
    );

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      executeSearch();
    });
  }

  void setFilter(SearchFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(
      filter: filter,
      currentLimit: _pageSize,
      hasMore: true,
    );
    if (state.query.trim().isNotEmpty) {
      executeSearch();
    }
  }

  String _cacheKey(String query, SearchFilter filter, int limit) =>
      '${query.trim().toLowerCase()}:${filter.name}:$limit';

  Future<void> executeSearch() async {
    final currentQuery = state.query.trim();
    if (currentQuery.isEmpty) return;

    final key = _cacheKey(currentQuery, state.filter, _pageSize);
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      state = state.copyWith(
        result: cached.result,
        isLoading: false,
        currentLimit: _pageSize,
        hasMore: cached.result.totalCount >= _pageSize,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentLimit: _pageSize,
      hasMore: true,
    );

    try {
      final repository = SearchRepository.instance;
      final result = await repository.search(
        currentQuery,
        filter: state.filter,
        limit: _pageSize,
      );

      if (state.query.trim() == currentQuery) {
        if (result != null) {
          _putCache(key, result);
          state = state.copyWith(
            result: result,
            isLoading: false,
            currentLimit: _pageSize,
            hasMore: result.totalCount >= _pageSize,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            clearResult: true,
            errorMessage: 'Search failed. Please try again.',
          );
        }
      }
    } catch (e) {
      if (state.query.trim() == currentQuery) {
        state = state.copyWith(
          isLoading: false,
          clearResult: true,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    final currentQuery = state.query.trim();
    if (currentQuery.isEmpty) return;

    final newLimit = state.currentLimit + _pageSize;
    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = SearchRepository.instance;
      final result = await repository.search(
        currentQuery,
        filter: state.filter,
        limit: newLimit,
      );

      if (state.query.trim() == currentQuery && result != null) {
        final prevTotal = state.result?.totalCount ?? 0;
        state = state.copyWith(
          result: result,
          isLoadingMore: false,
          currentLimit: newLimit,
          hasMore: result.totalCount > prevTotal,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void _putCache(String key, SearchResult result) {
    _cache[key] = _CacheEntry(result);
    if (_cache.length > _maxCacheSize) {
      _cache.entries
          .where((e) => e.value.isExpired)
          .map((e) => e.key)
          .toList()
          .forEach(_cache.remove);
      if (_cache.length > _maxCacheSize) {
        final oldest = _cache.entries.toList()
          ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
        for (var i = 0; i < oldest.length - _maxCacheSize; i++) {
          _cache.remove(oldest[i].key);
        }
      }
    }
  }
}
