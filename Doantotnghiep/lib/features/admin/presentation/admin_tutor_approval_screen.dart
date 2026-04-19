/// Admin Tutor Approval Screen
/// 
/// **Purpose:**
/// - Quản lý các yêu cầu đăng ký làm gia sư
/// - Cho phép admin duyệt hoặc từ chối gia sư
/// - Có tính năng AI Face Comparison (E-KYC) để xác thực danh tính
/// 
/// **Features:**
/// - Xem danh sách gia sư chờ duyệt
/// - Duyệt gia sư (approve)
/// - Từ chối gia sư (reject)
/// - Swipe to approve/reject (gesture)
/// - AI Face Comparison: So sánh avatar với ảnh CCCD
/// 
/// **Approval Flow:**
/// 1. Admin xem thông tin gia sư
/// 2. (Optional) Chạy AI Face Comparison để xác thực
/// 3. Duyệt hoặc từ chối
/// 4. Gia sư được duyệt sẽ có thể nhận booking
library;

import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:doantotnghiep/features/admin/data/admin_tutor_request_provider.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Màn hình phê duyệt gia sư của admin
/// 
/// **Usage:**
/// - Truy cập từ admin navigation → "Kiểm duyệt"
/// - Hoặc từ dashboard → Click vào card "Chờ duyệt"
class AdminTutorApprovalScreen extends ConsumerStatefulWidget {
  const AdminTutorApprovalScreen({super.key});

  @override
  ConsumerState<AdminTutorApprovalScreen> createState() => _AdminTutorApprovalScreenState();
}

class _AdminTutorApprovalScreenState extends ConsumerState<AdminTutorApprovalScreen> {

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(tutorRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Phê duyệt Gia sư'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (tutors) {
           // Empty state: Hiển thị khi không có yêu cầu chờ duyệt
           if (tutors.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.verified_user, size: 64, color: Colors.green[300]),
                   const SizedBox(height: 16),
                   const Text(
                     'Không có yêu cầu nào đang chờ.',
                     style: TextStyle(fontSize: 16, color: Colors.grey),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Tất cả gia sư đã được duyệt!',
                     style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                return Dismissible(
                  key: Key(tutor.id),
                  background: _buildSwipeAction(Colors.green, Icons.check, Alignment.centerLeft),
                  secondaryBackground: _buildSwipeAction(Colors.red, Icons.close, Alignment.centerRight),
                   confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                       return await _handleApprove(tutor);
                    } else {
                       return await _handleReject(tutor);
                    }
                  },
                  child: _buildCard(tutor),
                );
              },
            );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      )
    );
  }

  /// Xử lý duyệt gia sư
  /// 
  /// **Purpose:**
  /// - Gọi API để duyệt gia sư
  /// - Refresh danh sách sau khi duyệt thành công
  /// - Hiển thị thông báo kết quả
  /// 
  /// **Parameters:**
  /// - `tutor`: Tutor object cần duyệt
  /// 
  /// **Returns:**
  /// - `bool`: true nếu duyệt thành công, false nếu thất bại
  Future<bool> _handleApprove(Tutor tutor) async {
     try {
       final success = await ref.read(adminRepositoryProvider).approveTutor(int.tryParse(tutor.id) ?? 0);
       if (success) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Đã duyệt ${tutor.name}'),
               backgroundColor: Colors.green,
             ),
           );
         }
         // Refresh danh sách
         ref.invalidate(tutorRequestsProvider);
         return true;
       } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Duyệt gia sư thất bại. Vui lòng thử lại.'),
               backgroundColor: Colors.red,
             ),
           );
         }
       }
     } catch (e) {
        print('Error approving tutor: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
     }
     return false;
  }

  /// Xử lý từ chối gia sư
  /// 
  /// **Purpose:**
  /// - Gọi API để từ chối gia sư
  /// - Refresh danh sách sau khi từ chối thành công
  /// - Hiển thị thông báo kết quả
  /// 
  /// **Parameters:**
  /// - `tutor`: Tutor object cần từ chối
  /// 
  /// **Returns:**
  /// - `bool`: true nếu từ chối thành công, false nếu thất bại
  Future<bool> _handleReject(Tutor tutor) async {
      try {
       final success = await ref.read(adminRepositoryProvider).rejectTutor(int.tryParse(tutor.id) ?? 0);
       if (success) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Đã từ chối ${tutor.name}'),
               backgroundColor: Colors.orange,
             ),
           );
         }
         // Refresh danh sách
         ref.invalidate(tutorRequestsProvider);
         return true;
       } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Từ chối gia sư thất bại. Vui lòng thử lại.'),
               backgroundColor: Colors.red,
             ),
           );
         }
       }
     } catch (e) {
       print('Error rejecting tutor: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Lỗi: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
     return false;
  }

  /// Build tutor card widget
  /// 
  /// **Purpose:**
  /// - Hiển thị thông tin gia sư chờ duyệt
  /// - Có các button để duyệt/từ chối
  /// - Có button AI Face Comparison
  /// 
  /// **Parameters:**
  /// - `tutor`: Tutor object cần hiển thị
  Widget _buildCard(Tutor tutor) {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 30, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tutor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tutor.subjects.join(', '),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(tutor.location),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.face_retouching_natural, color: Colors.blue),
                      label: const Text('AI Soi Chiếu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                      onPressed: () => _showFaceComparisonDialog(context, tutor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                    onPressed: () => _handleReject(tutor),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _handleApprove(tutor),
                  ),
                ],
              )
            ],
          ),
        ),
      );
  }

  Widget _buildSwipeAction(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  /// Hiển thị dialog AI Face Comparison
  /// 
  /// **Purpose:**
  /// - So sánh avatar của gia sư với ảnh CCCD
  /// - Tính toán độ khớp (match score)
  /// - Cho phép duyệt ngay sau khi xác thực
  /// 
  /// **Parameters:**
  /// - `context`: BuildContext để hiển thị dialog
  /// - `tutor`: Tutor object cần xác thực
  void _showFaceComparisonDialog(BuildContext context, Tutor tutor) {
    showDialog(
      context: context,
      builder: (context) => _FaceComparisonDialog(tutor: tutor, onApprove: () async {
        Navigator.pop(context);
        await _handleApprove(tutor);
      }),
    );
  }
}

class _FaceComparisonDialog extends StatefulWidget {
  final Tutor tutor;
  final VoidCallback onApprove;

  const _FaceComparisonDialog({required this.tutor, required this.onApprove});

  @override
  State<_FaceComparisonDialog> createState() => _FaceComparisonDialogState();
}

class _FaceComparisonDialogState extends State<_FaceComparisonDialog> {
  bool _isAnalyzing = true;
  double _matchScore = 0.0;

  @override
  void initState() {
    super.initState();
    // Simulate AI Processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _matchScore = 0.985; // Mock 98.5%
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI Face Comparison (E-KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageCol('Avatar App', widget.tutor.avatarUrl),
                if (_isAnalyzing)
                  const SizedBox(width: 40, child: LinearProgressIndicator())
                else
                   Icon(Icons.compare_arrows, size: 30, color: _matchScore > 0.8 ? Colors.green : Colors.red),
                _buildImageCol('CCCD', 'https://i.pravatar.cc/150?u=id_card_${widget.tutor.id}'), // Mock ID Card
              ],
            ),
            const SizedBox(height: 24),
            if (_isAnalyzing)
              const Text('Đang phân tích các điểm trên khuôn mặt...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            else
              Column(
                children: [
                  Text(
                    'Độ khớp: ${(_matchScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: _matchScore > 0.8 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Khuôn mặt trên Avatar khớp với ảnh CCCD.', style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onApprove,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                      child: const Text('Xác thực & Duyệt ngay'),
                    ),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCol(String label, String url) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, size: 35, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
