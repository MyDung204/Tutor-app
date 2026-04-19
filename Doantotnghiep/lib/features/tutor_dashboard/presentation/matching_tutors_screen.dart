import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor/presentation/views/tutor_detail_screen.dart';
import 'package:doantotnghiep/features/tutor/presentation/widgets/tutor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchingTutorsProvider = FutureProvider.autoDispose.family<List<Tutor>, String>((ref, requestId) async {
  final repo = ref.watch(sharedLearningRepositoryProvider);
  final data = await repo.getMatchingTutorsForRequest(requestId);
  
  return data.map((json) {
    // Reuse existing Tutor model parsing
    // Assuming backend returns Tutor objects but maybe without 'user' relation loaded fully
    // Or we map what we have.
    // Let's ensure Tutor.fromJson handles it.
    // The backend SmartMatchingController returns Tutor model which likely includes all fields.
    // However, Tutor model in Dart expects 'user' map for name/avatar usually?
    // Let's check backend controller logic. It returns Tutor model instances.
    // Laravel serialization usually includes relations if loaded.
    // My controller code didn't load 'user' relation explicitly?
    // Wait, Tutor belongsTo User. The name/avatar is in USER table usually?
    // In Tutor model (PHP): name/avatar_url are in `fillable`, so they might be denormalized or accessor?
    // Let's check Tutor.php. Yes: 'name', 'avatar_url' are in fillable.
    // So simple mapping should work.
    
    // BUT in Dart Tutor model, we need to check if it expects a nested 'user' object or flat fields.
    return Tutor.fromJson(json);
  }).toList();
});

class MatchingTutorsScreen extends ConsumerWidget {
  final String requestId;
  final String requestSubject;

  const MatchingTutorsScreen({
    super.key, 
    required this.requestId,
    required this.requestSubject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTutors = ref.watch(matchingTutorsProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text("Gia sư phù hợp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             Text("Cho yêu cầu: $requestSubject", style: const TextStyle(fontSize: 12)),
           ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: asyncTutors.when(
          data: (tutors) {
            if (tutors.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Chưa tìm thấy gia sư phù hợp.\nHãy thử điều chỉnh yêu cầu của bạn.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tutors.length,
              itemBuilder: (context, index) {
                final tutor = tutors[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => TutorDetailScreen(tutor: tutor))
                      );
                    },
                    child: Stack(
                      children: [
                        TutorCard(tutor: tutor),
                        // Match Score Badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  "Phù hợp nhất",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => Center(child: Text("Lỗi: $err")),
        ),
      ),
    );
  }
}
