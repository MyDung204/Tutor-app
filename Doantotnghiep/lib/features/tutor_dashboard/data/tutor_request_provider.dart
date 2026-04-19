import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TutorRequestsNotifier extends AsyncNotifier<List<TutorRequest>> {
  @override
  Future<List<TutorRequest>> build() async {
    final repo = ref.watch(sharedLearningRepositoryProvider);
    try {
      final requestsData = await repo.getTutorRequests();
      
      return requestsData.map((data) {
        final student = data['student'] ?? {};
        return TutorRequest(
          id: data['id'].toString(),
          studentId: data['student_id']?.toString() ?? '',
          studentName: student['name'] ?? 'Học viên',
          subject: data['subject'] ?? '',
          gradeLevel: data['grade_level'] ?? '',
          minBudget: double.tryParse(data['min_budget']?.toString() ?? '0') ?? 0,
          maxBudget: double.tryParse(data['max_budget']?.toString() ?? '0') ?? 0,
          schedule: data['schedule'] ?? 'Thỏa thuận',
          description: data['description'] ?? '',
          location: data['location'] ?? data['mode'] ?? 'Online',
          createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now(),
          status: data['status'] ?? 'open',
        );
      }).toList();
    } catch (e) {
      print('Error fetching requests: $e');
      return [];
    }
  }

  Future<void> addRequest(TutorRequest request) async {
    final repo = ref.read(sharedLearningRepositoryProvider);
    // TODO: Implement proper ID generation or let backend handle it
    // Mapping TutorRequest back to GroupRequest requires importing GroupRequest model
    // For now, we print to fix compilation and invalidate.
    print('Adding request: ${request.subject}');
    ref.invalidateSelf();
  }

  Future<void> removeRequest(String id) async {
     final repo = ref.read(sharedLearningRepositoryProvider);
     final success = await repo.deleteTutorRequest(id);
     
     if (success) {
       // Refresh public list
       ref.invalidateSelf();
       // Refresh student's own list
       ref.invalidate(myTutorRequestsProvider);
     }
  }
}

final tutorRequestsProvider = AsyncNotifierProvider<TutorRequestsNotifier, List<TutorRequest>>(TutorRequestsNotifier.new);

final myTutorRequestsProvider = FutureProvider.autoDispose<List<TutorRequest>>((ref) async {
  final repo = ref.watch(sharedLearningRepositoryProvider);
  final data = await repo.getMyTutorRequests();
  
  return data.map((d) {
    return TutorRequest(
      id: d['id'].toString(),
      studentId: d['student_id']?.toString() ?? '',
      studentName: 'Tôi', // My requests, so it's me.
      subject: d['subject'] ?? '',
      gradeLevel: d['grade_level'] ?? '',
      minBudget: double.tryParse(d['min_budget']?.toString() ?? '0') ?? 0,
      maxBudget: double.tryParse(d['max_budget']?.toString() ?? '0') ?? 0,
      schedule: d['schedule'] ?? 'Thỏa thuận',
      description: d['description'] ?? '',
      location: d['location'] ?? d['mode'] ?? 'Online',
      createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
      status: d['status'] ?? 'open',
    );
  }).toList();
});

final matchingRequestsProvider = FutureProvider.autoDispose<List<TutorRequest>>((ref) async {
  final repo = ref.watch(sharedLearningRepositoryProvider);
  final data = await repo.getMatchingRequestsForTutor();
  
  return data.map((d) {
    final student = d['student'] ?? {};
    return TutorRequest(
      id: d['id'].toString(),
      studentId: d['student_id']?.toString() ?? '',
      studentName: student['name'] ?? 'Học viên',
      subject: d['subject'] ?? '',
      gradeLevel: d['grade_level'] ?? '',
      minBudget: double.tryParse(d['min_budget']?.toString() ?? '0') ?? 0,
      maxBudget: double.tryParse(d['max_budget']?.toString() ?? '0') ?? 0,
      schedule: d['schedule'] ?? 'Thỏa thuận',
      description: d['description'] ?? '',
      location: d['location'] ?? d['mode'] ?? 'Online',
      createdAt: d['created_at'] != null ? DateTime.parse(d['created_at']) : DateTime.now(),
      status: d['status'] ?? 'open',
    );
  }).toList();
});
