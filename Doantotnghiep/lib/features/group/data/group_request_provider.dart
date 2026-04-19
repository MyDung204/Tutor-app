import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/search/presentation/view_models/search_view_model.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupRequestsProvider = FutureProvider<List<GroupRequest>>((ref) async {
  final repo = ref.watch(sharedLearningRepositoryProvider);
  final allGroups = await repo.getStudyGroups();

  final searchState = ref.watch(searchViewModelProvider);
  final query = searchState.query.toLowerCase();
  final filter = searchState.filter;

  return allGroups.where((group) {
    bool matchesQuery = true;
    if (query.isNotEmpty) {
      matchesQuery = group.subject.toLowerCase().contains(query) || 
                     group.topic.toLowerCase().contains(query);
    }

    bool matchesFilter = true;
    if (filter != null) {
       // Filter by specific subjects if selected
       if (filter.subjects != null && filter.subjects!.isNotEmpty) {
         // Check if group subject is loosely in the selected list
         bool subjectMatch = false;
         for (var s in filter.subjects!) {
            if (group.subject.toLowerCase().contains(s.toLowerCase())) {
               subjectMatch = true;
               break;
            }
         }
         if (!subjectMatch) matchesFilter = false;
       }

       // Filter by location
       if (filter.location != null && filter.location!.isNotEmpty) {
          if (!group.location.toLowerCase().contains(filter.location!.toLowerCase())) {
             matchesFilter = false;
          }
       }
       
       // Filter by Price (if pricePerSession > 0)
       if (group.pricePerSession > 0) {
          if (filter.minPrice != null && group.pricePerSession < filter.minPrice!) matchesFilter = false;
          if (filter.maxPrice != null && group.pricePerSession > filter.maxPrice!) matchesFilter = false;
       }
    }

    return matchesQuery && matchesFilter;
  }).toList();
});

final myAllGroupsProvider = FutureProvider<List<GroupRequest>>((ref) async {
  return ref.watch(sharedLearningRepositoryProvider).getMyStudyGroups();
});

final myCreatedGroupsProvider = Provider<AsyncValue<List<GroupRequest>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final allGroups = ref.watch(myAllGroupsProvider);
  
  return allGroups.whenData((groups) {
    if (user == null) return [];
    return groups.where((g) => g.creatorId == user.id).toList();
  });
});

final myJoinedGroupsProvider = Provider<AsyncValue<List<GroupRequest>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  final allGroups = ref.watch(myAllGroupsProvider);
  
  return allGroups.whenData((groups) {
    if (user == null) return [];
    return groups.where((g) => g.creatorId != user.id).toList();
  });
});

// Deprecated: maintain for backward compatibility if needed, or replace usages
final myGroupsProvider = myAllGroupsProvider;
