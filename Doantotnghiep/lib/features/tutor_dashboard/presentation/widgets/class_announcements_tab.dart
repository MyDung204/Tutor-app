import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/announcement.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final courseAnnouncementsProvider = FutureProvider.family<List<Announcement>, String>((ref, courseId) {
  return ref.watch(sharedLearningRepositoryProvider).getAnnouncements(courseId);
});

class ClassAnnouncementsTab extends ConsumerStatefulWidget {
  final Course course;
  final bool isTutor;

  const ClassAnnouncementsTab({
    super.key,
    required this.course,
    required this.isTutor,
  });

  @override
  ConsumerState<ClassAnnouncementsTab> createState() => _ClassAnnouncementsTabState();
}

class _ClassAnnouncementsTabState extends ConsumerState<ClassAnnouncementsTab> {
  
  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo thông báo mới'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung thông báo...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final content = controller.text;
                Navigator.pop(context);
                
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang đăng thông báo...'), duration: Duration(seconds: 1)),
                );
                
                final result = await ref.read(sharedLearningRepositoryProvider).createAnnouncement(widget.course.id, content);
                
                if (context.mounted) {
                  // Hide loading snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  
                  if (result != null) {
                    // Show success IMMEDIATELY
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đăng thông báo thành công!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Force refresh and wait for it
                    await ref.refresh(courseAnnouncementsProvider(widget.course.id).future);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Có lỗi xảy ra. Vui lòng thử lại.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Đăng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(courseAnnouncementsProvider(widget.course.id));

    return announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(courseAnnouncementsProvider(widget.course.id)),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                   height: MediaQuery.of(context).size.height * 0.7,
                   child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có thông báo nào',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (widget.isTutor) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreateDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo thông báo đầu tiên'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(courseAnnouncementsProvider(widget.course.id)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length + (widget.isTutor ? 2 : 1), // Header (if tutor) + Items + Padding
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                // 1. Header: Create Post (Only for Tutor)
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
                              child: const Icon(Icons.edit, color: EduTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Tạo thông báo mới...',
                              style: TextStyle(color: Colors.grey[600], fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Adjust index if header exists
                final int itemIndex = widget.isTutor ? index - 1 : index;

                // 2. Padding Bottom
                if (itemIndex == announcements.length) return const SizedBox(height: 80);

                // 3. Announcement Item
                final item = announcements[itemIndex];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: EduTheme.primary.withOpacity(0.1),
                              backgroundImage: item.author?.avatarUrl != null ? NetworkImage(item.author!.avatarUrl!) : null,
                              child: item.author?.avatarUrl == null ? const Icon(Icons.person, size: 18, color: EduTheme.primary) : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.author?.name ?? 'Giảng viên',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  DateFormat('dd/MM HH:mm').format(item.createdAt),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.content,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ],
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
}
