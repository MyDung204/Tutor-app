import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';
import 'package:doantotnghiep/features/student/presentation/my_requests_screen.dart'; // Reusing widgets?? No, better clean copy or shared widget. 
// Actually, StudentRequestListScreen has the card _buildRequestCard. I should reuse or extract.
// For now, I'll copy the logic to keep it simple and independent.

import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart'; // For Chat target model
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RecommendedRequestsScreen extends ConsumerWidget {
  const RecommendedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(matchingRequestsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Việc làm phù hợp'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Chưa có yêu cầu nào phù hợp với hồ sơ của bạn.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/tutor-profile-edit'),
                    child: const Text('Cập nhật hồ sơ để nhận gợi ý tốt hơn'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                           Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.class_outlined, color: Colors.blue),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Tìm gia sư ${req.subject}',
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(req.studentName, style: const TextStyle(color: Colors.grey)),
                               ],
                             ),
                           ),
                           // MATCH BADGE
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.green,
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Text('Phù hợp', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                           ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(req.location, style: TextStyle(color: Colors.grey[600])),
                          const Spacer(),
                          Text(
                            '${currencyFormat.format(req.maxBudget)}/h',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                             final studentAsTarget = Tutor(
                                id: req.studentId,
                                userId: req.studentId,
                                name: req.studentName,
                                bio: 'Học viên',
                                hourlyRate: 0,
                                subjects: [],
                                rating: 0,
                                reviewCount: 0,
                                avatarUrl: 'https://i.pravatar.cc/150?u=${req.studentId}',
                                location: req.location,
                                gender: 'Khác',
                                teachingMode: [],
                                address: '',
                                weeklySchedule: {},
                              );

                              context.push('/chat', extra: {
                                'tutor': studentAsTarget,
                                'request': req,
                              });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Nhận dạy ngay', style: TextStyle(color: Colors.white)),
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
        error: (e, s) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
