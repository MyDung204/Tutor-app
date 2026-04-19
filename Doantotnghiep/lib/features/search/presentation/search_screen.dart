import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:doantotnghiep/features/search/presentation/widgets/class_listing_tab.dart';
import 'package:doantotnghiep/features/search/presentation/widgets/group_matching_tab.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:doantotnghiep/features/search/domain/models/search_filter.dart';
import 'package:doantotnghiep/features/search/presentation/view_models/search_view_model.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor/presentation/widgets/tutor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';

// Provider for user's tutor requests
final myRequestsProvider = Provider.autoDispose<AsyncValue<List<TutorRequest>>>((ref) {
  final allRequestsAsync = ref.watch(tutorRequestsProvider);
  final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid ?? 'test-user-id';
  
  return allRequestsAsync.whenData((list) => list.where((req) => req.studentId == userId).toList());
});

// Provider to filter tutors - uses ViewModel state
final searchResultsProvider = FutureProvider.autoDispose<List<Tutor>>((ref) async {
  final searchState = ref.watch(searchViewModelProvider);
  return ref.read(tutorRepositoryProvider).searchTutors(
    searchState.query,
    filter: searchState.filter,
  );
});

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialSubject;
  const SearchScreen({super.key, this.initialSubject});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _queryController;
  final bool _isFilterInitialized = false;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    
    // Initialize ViewModel
    if (widget.initialSubject != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchViewModelProvider.notifier)
            .initializeFilterWithSubject(widget.initialSubject!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchViewModelProvider.notifier).markFilterInitialized();
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchViewModelProvider);
    final searchViewModel = ref.read(searchViewModelProvider.notifier);
    final searchResults = ref.watch(searchResultsProvider);

    if (!searchState.isFilterInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _queryController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _queryController.clear();
                  searchViewModel.clearQuery();
                },
              ),
            ),
            onChanged: (value) {
              searchViewModel.updateQuery(value);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                _showFilterModal(context, ref, searchViewModel);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tìm Gia sư'),
              Tab(text: 'Học ghép'),
              Tab(text: 'Lớp học'),
            ],
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Tutor Search (Existing)
            // Tab 1: Tutor Search
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/create-tutor-request');
                          },
                          icon: const Icon(Icons.post_add),
                          label: const Text('Đăng tìm gia sư', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            elevation: 2,
                          ),
                        ),
                      ),
                      // My Requests Section
                      Consumer(
                        builder: (context, ref, child) {
                          final requestsAsync = ref.watch(myRequestsProvider);
                          
                          return requestsAsync.when(
                            skipLoadingOnRefresh: true,
                            data: (requests) {
                              if (requests.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  const Text('Yêu cầu của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: requests.length,
                                      itemBuilder: (context, index) {
                                        final req = requests[index];
                                        return GestureDetector(
                                          onTap: () => context.push('/my-request-detail', extra: req),
                                          child: Container(
                                            width: 240,
                                            margin: const EdgeInsets.only(right: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                              boxShadow: [
                                                BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3)),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(req.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                    Text(req.gradeLevel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                  ],
                                                ),
                                                Text(
                                                  '${(req.minBudget/1000).toInt()}k - ${(req.maxBudget/1000).toInt()}k',
                                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('Đang tìm...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                                    const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const Divider(height: 30),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: searchResults.when(
                    skipLoadingOnRefresh: true,
                    data: (tutors) {
                      if (tutors.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async => ref.refresh(searchResultsProvider),
                          child: Stack(
                            children: [
                              ListView(), // Empty list view to allow pull-to-refresh
                              const Center(child: Text('Không tìm thấy kết quả nào.')),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                           return ref.refresh(searchResultsProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: tutors.length,
                          itemBuilder: (context, index) {
                            final tutor = tutors[index];
                            return TutorCard(
                              tutor: tutor,
                              onTap: () {
                                context.push('/tutor-detail', extra: tutor);
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Lỗi: $err')),
                  ),
                ),
              ],
            ),
            
            // Tab 2: Group Matching
            const GroupMatchingTab(),
            
            // Tab 3: Classes
            const ClassListingTab(),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(
    BuildContext context,
    WidgetRef ref,
    SearchViewModel viewModel,
  ) {
    // Read current filter or default
    final currentFilter = ref.read(searchViewModelProvider).filter ??
        const SearchFilter(
          minPrice: 50000,
          maxPrice: 1000000,
          gender: 'Bất kỳ',
          teachingMode: [],
          subjects: [],
        );

    // Temp state for modal
    double minPrice = currentFilter.minPrice ?? 50000;
    double maxPrice = currentFilter.maxPrice ?? 1000000;
    List<String> selectedModes = List.from(currentFilter.teachingMode ?? []);
    String selectedGender = currentFilter.gender ?? 'Bất kỳ';
    String? selectedLocation = currentFilter.location;
    List<String> selectedSubjects = List.from(currentFilter.subjects ?? []);
    List<String> selectedDegrees = List.from(currentFilter.degrees ?? []);
    double? selectedMinRating = currentFilter.minRating;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true, // Allow full height usage if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bộ lọc tìm kiếm', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            viewModel.clearFilter();
                            context.pop();
                          },
                          child: const Text('Xóa lọc'),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Mức giá: ${(minPrice/1000).toInt()}k - ${(maxPrice/1000).toInt()}k', style: const TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: RangeValues(minPrice, maxPrice),
                      min: 50000,
                      max: 1000000,
                      divisions: 19,
                      labels: RangeLabels('${(minPrice/1000).toInt()}k', '${(maxPrice/1000).toInt()}k'),
                      onChanged: (values) {
                        setModalState(() {
                          minPrice = values.start;
                          maxPrice = values.end;
                        });
                      }, 
                    ),
                    const SizedBox(height: 16),
                    const Text('Hình thức học', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: ['Online', 'Offline'].map((mode) {
                        final isSelected = selectedModes.contains(mode);
                        return FilterChip(
                          label: Text(mode),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedModes.add(mode);
                              } else {
                                selectedModes.remove(mode);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                     const Text('Giới tính Gia sư', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: ['Nam', 'Nữ', 'Bất kỳ'].map((gender) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(gender),
                            selected: selectedGender == gender,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => selectedGender = gender);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                     const SizedBox(height: 16),
                    const Text('Khu vực', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLocation,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        hintText: 'Chọn Quận/Huyện',
                      ),
                      items: ['Q.1', 'Q.3', 'Q.5', 'Q.10', 'Bình Thạnh', 'Hà Nội', 'Đà Nẵng']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                         setModalState(() => selectedLocation = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Môn học', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: ['Toán', 'Lý', 'Hóa', 'Tiếng Anh', 'Văn', 'IELTS', 'Piano']
                          .map((e) => FilterChip(
                                label: Text(e),
                                selected: selectedSubjects.contains(e),
                                onSelected: (selected) {
                                   setModalState(() {
                                     if (selected) {
                                       selectedSubjects.add(e);
                                     } else {
                                       selectedSubjects.remove(e);
                                     }
                                   });
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Trình độ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: ['Sinh viên', 'Giáo viên', 'Thạc sĩ', 'Giảng viên'].map((e) {
                         // Temporary local state for degrees if not defined in build scope
                         // Assuming we added 'List<String> selectedDegrees' above
                         return FilterChip(
                                label: Text(e),
                                selected: selectedDegrees.contains(e),
                                onSelected: (selected) {
                                   setModalState(() {
                                     if (selected) {
                                       selectedDegrees.add(e);
                                     } else {
                                       selectedDegrees.remove(e);
                                     }
                                   });
                                },
                              );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: [5.0, 4.0, 3.0].map((rating) {
                        return ChoiceChip(
                          label: Text('$rating★ trở lên'),
                          selected: selectedMinRating == rating,
                          onSelected: (selected) {
                            setModalState(() {
                               selectedMinRating = selected ? rating : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Apply Filter using ViewModel
                          viewModel.applyFilter(
                            minPrice: minPrice,
                            maxPrice: maxPrice,
                            teachingMode: selectedModes,
                            gender: selectedGender,
                            location: selectedLocation,
                            subjects: selectedSubjects,
                            minRating: selectedMinRating,
                            degrees: selectedDegrees,
                          );
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Áp dụng bộ lọc'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
