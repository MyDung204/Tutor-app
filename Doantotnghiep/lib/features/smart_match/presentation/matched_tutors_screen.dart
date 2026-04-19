import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';
import '../data/smart_match_repository.dart';

final matchedTutorsProvider = FutureProvider.family<List<dynamic>, List<String>>((ref, tags) async {
  return ref.read(smartMatchRepositoryProvider).getMatches(tags);
});

class MatchedTutorsScreen extends ConsumerWidget {
  final List<String> tags;

  const MatchedTutorsScreen({super.key, required this.tags});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchedTutorsProvider(tags));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Smart Matches'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: matchesAsync.when(
        data: (tutors) {
          if (tutors.isEmpty) {
            return const Center(child: Text('No matches found. Try different tags.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tutors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final tutor = tutors[index];
              final score = tutor['match_score'] ?? 0;
              final user = tutor['user'] ?? {};

              return InkWell(
                onTap: () {
                    // Navigate to Tutor Detail
                    context.push('/tutor/${tutor['id']}'); 
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(tutor['avatar_url'] ?? 'https://via.placeholder.com/150'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('AI', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tutor['name'] ?? 'Unknown Tutor',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$score% Match',
                                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tutor['hourly_rate'] != null ? '\$${tutor['hourly_rate']}/hr' : 'Price N/A',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                             const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: (tutor['teaching_tags'] as List<dynamic>? ?? []).take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tag.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
