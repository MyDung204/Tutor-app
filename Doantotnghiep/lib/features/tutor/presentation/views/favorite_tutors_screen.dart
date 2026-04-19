import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:doantotnghiep/features/tutor/presentation/widgets/tutor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final favoriteTutorsProvider = FutureProvider.autoDispose<List<Tutor>>((ref) async {
  final repo = ref.watch(tutorRepositoryProvider);
  return repo.getFavoriteTutors();
});

class FavoriteTutorsScreen extends ConsumerWidget {
  const FavoriteTutorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTutors = ref.watch(favoriteTutorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gia sư yêu thích'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteTutorsProvider);
          await ref.read(favoriteTutorsProvider.future);
        },
        child: asyncTutors.when(
          skipLoadingOnRefresh: true,
          data: (tutors) {
            if (tutors.isEmpty) {
              return ListView(
                children: [
                   SizedBox(
                     height: MediaQuery.of(context).size.height * 0.6,
                     child: const Center(
                        child: Text(
                          'Bạn chưa có gia sư yêu thích nào.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                     ),
                   ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tutors.length,
              itemBuilder: (context, index) {
                final tutor = tutors[index];
                return TutorCard(
                  tutor: tutor,
                  onTap: () => context.push('/tutor-detail', extra: tutor),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            children: [
              SizedBox(
                 height: MediaQuery.of(context).size.height * 0.6,
                 child: Center(
                   child: Text('Lỗi tải dữ liệu: $error'),
                 ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
