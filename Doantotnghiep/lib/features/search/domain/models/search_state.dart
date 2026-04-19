import 'package:doantotnghiep/features/search/domain/models/search_filter.dart';

/// State class for Search feature
class SearchState {
  final String query;
  final SearchFilter? filter;
  final bool isFilterInitialized;
  final bool isLoading;

  const SearchState({
    required this.query,
    this.filter,
    this.isFilterInitialized = false,
    this.isLoading = false,
  });

  factory SearchState.initial() => const SearchState(
        query: '',
        filter: null,
        isFilterInitialized: false,
      );

  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    bool? isFilterInitialized,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
      isFilterInitialized: isFilterInitialized ?? this.isFilterInitialized,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}



