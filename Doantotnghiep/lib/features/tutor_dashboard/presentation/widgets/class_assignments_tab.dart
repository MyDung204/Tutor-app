
import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/assignment.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/assignment_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final courseAssignmentsProvider = FutureProvider.family<List<Assignment>, int>((ref, courseId) {
  return ref.watch(sharedLearningRepositoryProvider).getAssignments(courseId);
});

class ClassAssignmentsTab extends ConsumerStatefulWidget {
  final Course course;
  final bool isTutor;

  const ClassAssignmentsTab({
    super.key,
    required this.course,
    required this.isTutor,
  });

  @override
  ConsumerState<ClassAssignmentsTab> createState() => _ClassAssignmentsTabState();
}

class _ClassAssignmentsTabState extends ConsumerState<ClassAssignmentsTab> {
  void _showCreateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final parentContext = context; // Capture parent context for ScaffoldMessenger
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog( // Rename to dialogContext
        title: const Text('Giao bài tập mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nội dung / Yêu cầu',
                border: OutlineInputBorder(),
                hintText: 'Nhập yêu cầu bài tập...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                // 1. Close dialog first
                Navigator.pop(dialogContext);
                
                // 2. Show loading on PARENT context
                if (parentContext.mounted) {
                   ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Đang tạo bài tập...')));
                }
                
                // 3. Perform API call
                try {
                  print('Creating assignment for course: ${widget.course.id}');
                  final result = await ref.read(sharedLearningRepositoryProvider).createAssignment({
                    'course_id': widget.course.id,
                    'title': titleController.text,
                    'description': contentController.text,
                  });
                  
                  // 4. Handle result using PARENT context
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
                    if (result != null) {
                        print('Assignment created successfully: ${result.id}');
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Đã giao bài tập thành công!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        // 5. Invalidate using REF
                        print('Invalidating provider for course ${widget.course.id}');
                        ref.invalidate(courseAssignmentsProvider(int.tryParse(widget.course.id) ?? 0));
                    } else {
                        // Fallback unknown error
                        print('Assignment creation returned null');
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Có lỗi xảy ra. Vui lòng thử lại.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  }
                } catch (e) {
                   if (parentContext.mounted) {
                      ScaffoldMessenger.of(parentContext).hideCurrentSnackBar();
                      String errorMessage = '❌ Có lỗi xảy ra.';
                      if (e.toString().contains('ApiException')) {
                         // Extract user message if simple string, or rely on type check if imported
                         errorMessage = '❌ ${e.toString()}'; 
                         // Note: In real app, cast to ApiException to get .userMessage
                      }
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                   }
                }
              }
            },
            child: const Text('Giao bài'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure consistent ID parsing
    final courseIdInt = int.tryParse(widget.course.id) ?? 0;
    
    final assignmentsAsync = ref.watch(courseAssignmentsProvider(courseIdInt));

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty && !widget.isTutor) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Chưa có bài tập nào', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(courseAssignmentsProvider(courseIdInt)),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: assignments.length + (widget.isTutor ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (widget.isTutor && index == 0) {
                 return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: EduTheme.primary.withOpacity(0.2)),
                    ),
                    child: InkWell(
                      onTap: _showCreateDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: EduTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.add_task, color: EduTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Giao bài tập mới...',
                              style: TextStyle(color: Colors.grey[600], fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
              }

              final itemIndex = widget.isTutor ? index - 1 : index;
              final item = assignments[itemIndex];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignmentDetailScreen(
                          assignment: item,
                          isTutor: widget.isTutor,
                        ),
                      ),
                    ).then((_) => ref.refresh(courseAssignmentsProvider(courseIdInt))); // Refresh when coming back
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.assignment, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(item.createdAt),
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isTutor)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(item.id),
                              )
                            else
                              _buildStudentStatusChip(item),
                          ],
                        ),
                        if (widget.isTutor) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.submissionCount} đã nộp',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const Spacer(),
                                const Text('Xem chi tiết', style: TextStyle(color: EduTheme.primary, fontWeight: FontWeight.bold)),
                                const Icon(Icons.arrow_forward_ios, size: 12, color: EduTheme.primary),
                              ],
                            ),
                          ),
                        ]
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
    );
  }

  Future<void> _confirmDelete(int assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài tập?'),
        content: const Text('Hành động này không thể hoàn tác. Tất cả bài nộp của học viên sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(sharedLearningRepositoryProvider).deleteAssignment(assignmentId);
      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã xóa bài tập')));
           ref.invalidate(courseAssignmentsProvider(int.tryParse(widget.course.id) ?? 0));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Xóa thất bại')));
        }
      }
    }
  }

  Widget _buildStudentStatusChip(Assignment item) {
    if (item.isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Text('Đã nộp', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Text('Chưa nộp', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
  }
}
