/// Search ViewModel
/// 
/// Manages search functionality with debouncing and filtering.
/// Implements MVVM pattern to separate business logic from UI.
/// 
/// **Key Features:**
/// - Debounced search (500ms) to reduce API calls
/// - Filter management (price, location, gender, etc.)
/// - State management for search query and filters
/// 
/// **Debouncing:**
/// - Waits 500ms after user stops typing before updating query
/// - Prevents excessive API calls while user is typing
/// - Improves performance and reduces server load
library;

import 'dart:async';
import 'package:doantotnghiep/core/base/base_view_model.dart';
import 'package:doantotnghiep/features/search/domain/models/search_filter.dart';
import 'package:doantotnghiep/features/search/domain/models/search_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel for Search feature
/// 
/// Handles search query and filter state management with debouncing.
/// Separates business logic from UI for better testability and maintainability.
class SearchViewModel extends BaseStateNotifier<SearchState> {
  /// Timer for debouncing search queries
  /// Cancelled and recreated each time user types
  Timer? _debounceTimer;
  
  /// Debounce duration: 500ms
  /// 
  /// **Why 500ms?**
  /// - Long enough to wait for user to finish typing
  /// - Short enough to feel responsive
  /// - Balances performance and UX
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Constructor - initializes with initial state
  /// 
  /// **Parameters:**
  /// - `ref`: Ref for accessing providers (Riverpod 2.x)
  /// 
  /// **Note:** Riverpod 2.x StateNotifier requires ref and initial state in constructor
  SearchViewModel(Ref ref) : super(ref, SearchState.initial()) {
    // Setup cleanup when provider is disposed
    // Note: In Riverpod 2.x, cleanup is done via provider's onDispose callback
  }
  
  /// Cleanup method - should be called when provider is disposed
  /// 
  /// **Purpose:**
  /// - Cancels debounce timer to prevent memory leak
  /// - Called automatically by provider's onDispose
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Update search query with debounce
  /// 
  /// **Parameters:**
  /// - `query`: Search query string from user input
  /// 
  /// **Purpose:**
  /// - Updates search query in state
  /// - Debounces to prevent excessive API calls
  /// 
  /// **How it works:**
  /// 1. Cancels previous timer (if exists)
  /// 2. Creates new timer that waits 500ms
  /// 3. After 500ms, updates state with new query
  /// 4. If user types again within 500ms, timer is reset
  /// 
  /// **Example:**
  /// - User types "toán" → Timer starts (500ms)
  /// - User types "học" (after 200ms) → Timer resets (500ms again)
  /// - User stops typing → After 500ms, query "toán học" is set
  /// 
  /// **Performance:**
  /// - Without debounce: 10 API calls for "toán học" (10 characters)
  /// - With debounce: 1 API call (only after user stops typing)
  void updateQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        state = state.copyWith(query: query);
      }
    });
  }

  /// Clear search query
  /// 
  /// **Purpose:**
  /// - Resets search query to empty string
  /// - Cancels any pending debounce timer
  /// - Used when user clicks clear button in search bar
  void clearQuery() {
    _debounceTimer?.cancel(); // Cancel pending timer
    state = state.copyWith(query: '');
  }

  /// Update search filter
  /// 
  /// **Parameters:**
  /// - `filter`: SearchFilter object with filter criteria (price, location, etc.)
  ///   Can be null to remove all filters
  /// 
  /// **Purpose:**
  /// - Updates filter state
  /// - Triggers new search with updated filters
  void updateFilter(SearchFilter? filter) {
    state = state.copyWith(filter: filter);
  }

  /// Clear all search filters
  /// 
  /// **Purpose:**
  /// - Removes all filter criteria
  /// - Resets to default (no filters)
  /// - Used when user clicks "Clear filters" button
  void clearFilter() {
    state = state.copyWith(filter: null);
  }

  /// Initialize filter with a specific subject
  /// 
  /// **Parameters:**
  /// - `subject`: Subject name to filter by (e.g., "Toán", "Tiếng Anh")
  /// 
  /// **Purpose:**
  /// - Used when navigating to search screen with initial subject filter
  /// - Sets up default filter with subject pre-selected
  /// - Marks filter as initialized (allows search to proceed)
  /// 
  /// **Example:**
  /// - User clicks "Tìm gia sư Toán" from home screen
  /// - Search screen opens with subject "Toán" already filtered
  void initializeFilterWithSubject(String subject) {
    final defaultFilter = const SearchFilter(
      minPrice: 50000,
      maxPrice: 1000000,
      gender: 'Bất kỳ',
      teachingMode: [],
      subjects: [],
    );

    state = state.copyWith(
      filter: defaultFilter.copyWith(subjects: [subject]),
      isFilterInitialized: true,
    );
  }

  /// Mark filter as initialized
  /// 
  /// **Purpose:**
  /// - Signals that filter setup is complete
  /// - Allows search to proceed (prevents premature API calls)
  /// - Used when no initial subject is provided
  /// 
  /// **Why needed?**
  /// - Prevents search from running before filters are ready
  /// - Ensures consistent state during initialization
  void markFilterInitialized() {
    state = state.copyWith(isFilterInitialized: true);
  }

  /// Apply filter from filter modal
  /// 
  /// **Parameters:**
  /// - `minPrice`: Minimum hourly rate (VND)
  /// - `maxPrice`: Maximum hourly rate (VND)
  /// - `teachingMode`: List of teaching modes (e.g., ["Online", "Offline"])
  /// - `gender`: Gender filter ("Nam", "Nữ", "Bất kỳ")
  /// - `location`: Location filter (optional, e.g., "Q.1", "Hà Nội")
  /// - `subjects`: List of subjects to filter by (e.g., ["Toán", "Lý"])
  /// 
  /// **Purpose:**
  /// - Creates new SearchFilter from modal selections
  /// - Updates state with new filter
  /// - Triggers new search with updated criteria
  /// 
  /// **Called from:**
  /// - Filter modal "Áp dụng bộ lọc" button
  /// 
  /// **Example:**
  /// ```dart
  /// viewModel.applyFilter(
  ///   minPrice: 50000,
  ///   maxPrice: 200000,
  ///   teachingMode: ["Online"],
  ///   gender: "Nữ",
  ///   location: "Q.1",
  ///   subjects: ["Toán", "Lý"],
  /// );
  /// ```
  void applyFilter({
    required double minPrice,
    required double maxPrice,
    required List<String> teachingMode,
    required String gender,
    String? location,
    required List<String> subjects,
    double? minRating,
    List<String>? degrees,
  }) {
    final newFilter = SearchFilter(
      minPrice: minPrice,
      maxPrice: maxPrice,
      teachingMode: teachingMode,
      gender: gender,
      location: location,
      subjects: subjects,
      minRating: minRating,
      degrees: degrees,
    );

    state = state.copyWith(filter: newFilter);
  }
}

/// Provider for SearchViewModel
/// 
/// **Type:** Auto-dispose StateNotifierProvider (Riverpod 2.x)
/// 
/// **Purpose:**
/// - Creates SearchViewModel instance
/// - Automatically disposes when no longer used (memory efficient)
/// - Provides reactive state management for search feature
/// 
/// **Usage:**
/// ```dart
/// // Watch state
/// final searchState = ref.watch(searchViewModelProvider);
/// 
/// // Read notifier for actions
/// final viewModel = ref.read(searchViewModelProvider.notifier);
/// viewModel.updateQuery('toán');
/// ```
final searchViewModelProvider =
    StateNotifierProvider.autoDispose<SearchViewModel, SearchState>(
  (ref) {
    final viewModel = SearchViewModel(ref);
    // Setup cleanup when provider is disposed
    ref.onDispose(() {
      viewModel.dispose();
    });
    return viewModel;
  },
);


