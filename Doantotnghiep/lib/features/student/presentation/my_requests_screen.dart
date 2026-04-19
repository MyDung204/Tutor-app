/// My Tutor Requests Screen
/// 
/// **Purpose:**
/// - Hiển thị danh sách các yêu cầu tìm gia sư mà học viên đã tạo
/// - Cho phép học viên xem chi tiết, chỉnh sửa hoặc xóa yêu cầu
/// 
/// **Features:**
/// - Xem danh sách yêu cầu đã tạo
/// - Xem chi tiết yêu cầu (môn học, cấp độ, ngân sách, v.v.)
/// - Tạo yêu cầu mới (FAB button)
/// - Refresh danh sách
/// 
/// **Data Flow:**
/// - Fetches from `/my-tutor-requests` API endpoint
/// - Displays empty state if no requests
/// - Navigates to detail screen on tap
library;

import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/matching_tutors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Provider để lấy danh sách yêu cầu tìm gia sư của học viên
/// 
/// **Purpose:**
/// - Tự động fetch danh sách yêu cầu từ API
/// - Auto-dispose khi không còn sử dụng (tiết kiệm memory)
/// - Refresh khi cần thiết
final myTutorRequestsProvider = FutureProvider.autoDispose<List<TutorRequest>>((ref) async {
  final repo = ref.watch(sharedLearningRepositoryProvider);
  final list = await repo.getMyTutorRequests();
  return list.map((e) => TutorRequest.fromJson(e)).toList();
});

/// Màn hình hiển thị các yêu cầu tìm gia sư của học viên
/// 
/// **Usage:**
/// - Truy cập từ Profile Screen → "Yêu cầu tìm gia sư"
/// - Hiển thị tất cả yêu cầu mà user đã tạo
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myTutorRequestsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu tìm gia sư của tôi')),
      body: requestsAsync.when(
        data: (requests) {
          // Empty state: Hiển thị khi chưa có yêu cầu nào
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text(
                     'Bạn chưa có yêu cầu tìm gia sư nào.',
                     style: TextStyle(fontSize: 16, color: Colors.grey),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () => context.push('/create-tutor-request'),
                     icon: const Icon(Icons.add),
                     label: const Text('Tạo yêu cầu mới'),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     ),
                   )
                ],
              ),
            );
          }
          
          // List view: Hiển thị danh sách yêu cầu
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myTutorRequestsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      context.push('/my-request-detail', extra: req).then((_) {
                         // Refresh list when coming back from detail screen
                         ref.refresh(myTutorRequestsProvider);
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  req.subject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.school, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                req.gradeLevel,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                req.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                '${currencyFormat.format(req.minBudget)} - ${currencyFormat.format(req.maxBudget)}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đăng ngày: ${DateFormat('dd/MM/yyyy').format(req.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),

                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MatchingTutorsScreen(
                                      requestId: req.id,
                                      requestSubject: req.subject,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Tìm gia sư phù hợp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFe0c3fc).withOpacity(0.3),
                                foregroundColor: Colors.deepPurple,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-tutor-request'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
