import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/assignment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final courseAssignmentsProvider = FutureProvider.family<List<Assignment>, int>((ref, courseId) async {
  return ref.watch(sharedLearningRepositoryProvider).getAssignments(courseId);
});

class AssignmentListWidget extends ConsumerWidget {
  final int courseId;
  final bool isTutor;

  const AssignmentListWidget({super.key, required this.courseId, required this.isTutor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(courseAssignmentsProvider(courseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bài tập & Tài liệu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (isTutor)
              TextButton.icon(
                onPressed: () => _showCreateAssignmentDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Giao bài tập'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        assignmentsAsync.when(
          data: (assignments) {
             if (assignments.isEmpty) {
               return Container(
                 padding: const EdgeInsets.all(16),
                 width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.grey[100],
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: const Center(child: Text('Chưa có bài tập nào.')),
               );
             }
             
             return ListView.separated(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: assignments.length,
               separatorBuilder: (_, __) => const SizedBox(height: 8),
               itemBuilder: (context, index) {
                 final assignment = assignments[index];
                 return Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     border: Border.all(color: Colors.grey.shade200),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.blue.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Icon(Icons.assignment, color: Colors.blue, size: 20),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   assignment.title,
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                 ),
                                 if (assignment.dueDate != null)
                                   Text(
                                     'Hạn nộp: ${DateFormat('dd/MM HH:mm').format(assignment.dueDate!)}',
                                     style: TextStyle(color: Colors.red[400], fontSize: 12),
                                   ),
                               ],
                             ),
                           ),
                           if (isTutor)
                             IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                               onPressed: () => _confirmDelete(context, ref, assignment.id),
                             ),
                         ],
                       ),
                       if (assignment.description.isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Text(
                           assignment.description,
                           style: TextStyle(color: Colors.grey[700], fontSize: 13),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     ],
                   ),
                 );
               },
             );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Lỗi: $e'),
        ),
      ],
    );
  }

  void _showCreateAssignmentDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? dueDate;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Giao bài tập mới'),
          content: SingleChildScrollView(
            child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 TextField(
                   controller: titleController,
                   decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder()),
                 ),
                 const SizedBox(height: 12),
                 TextField(
                   controller: descController,
                   decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                   maxLines: 3,
                 ),
                 const SizedBox(height: 12),
                 ListTile(
                   title: Text(dueDate == null ? 'Chọn hạn nộp (Không bắt buộc)' : 'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(dueDate!)}'),
                   trailing: const Icon(Icons.calendar_today),
                   onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                           setState(() {
                             dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                           });
                        }
                      }
                   },
                 ),
               ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                 if (titleController.text.isEmpty) return;
                 Navigator.pop(context);
                 
                 final data = {
                   'course_id': courseId,
                   'title': titleController.text,
                   'description': descController.text,
                   'due_date': dueDate?.toIso8601String(),
                 };
                 
                 final res = await ref.read(sharedLearningRepositoryProvider).createAssignment(data);
                 if (res != null) {
                    ref.refresh(courseAssignmentsProvider(courseId));
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã giao bài tập thành công')));
                 }
              },
              child: const Text('Giao bài'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Xóa bài tập'),
         content: const Text('Bạn có chắc muốn xóa bài tập này không?'),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
           TextButton(
             onPressed: () async {
                Navigator.pop(context);
                await ref.read(sharedLearningRepositoryProvider).deleteAssignment(id);
                ref.refresh(courseAssignmentsProvider(courseId));
             },
             child: const Text('Xóa', style: TextStyle(color: Colors.red)),
           ),
         ],
       ),
     );
  }
}
