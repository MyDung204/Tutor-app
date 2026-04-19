import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/admin/data/admin_system_provider.dart';
import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';

class AdminSystemSettingsScreen extends ConsumerStatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  ConsumerState<AdminSystemSettingsScreen> createState() => _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends ConsumerState<AdminSystemSettingsScreen> {
  void _showSubjectDialog([Map<String, dynamic>? subject]) {
    final isEdit = subject != null;
    final nameCtrl = TextEditingController(text: isEdit ? subject['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? subject['description'] : '');
    bool isActive = isEdit ? (subject['is_active'] == 1 || subject['is_active'] == true) : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(isEdit ? 'Sửa môn học' : 'Thêm môn học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên môn học (*)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Trạng thái hoạt động'),
                  value: isActive,
                  onChanged: (val) => setStateDialog(() => isActive = val),
                  contentPadding: EdgeInsets.zero,
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                
                final repo = ref.read(adminRepositoryProvider);
                final data = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'is_active': isActive ? 1 : 0
                };

                bool success;
                if (isEdit) {
                  success = await repo.updateSubject(subject['id'], data);
                } else {
                  success = await repo.createSubject(data);
                }

                if (success) {
                  ref.invalidate(adminSubjectsProvider);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${isEdit ? 'Sửa' : 'Thêm'} thành công')));
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra')));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSubject(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    final success = await repo.deleteSubject(id);
    if (success) {
      ref.invalidate(adminSubjectsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thành công')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại. Có thể do môn học đang được sử dụng.')));
    }
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa môn "$name" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSubject(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Xóa'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(adminSubjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình Danh mục'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminSubjectsProvider),
            tooltip: 'Làm mới',
          )
        ],
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào. Hãy tạo mới.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sub = subjects[index];
              final isActive = sub['is_active'] == 1 || sub['is_active'] == true;
              
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(sub['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(sub['description'] ?? 'Không có mô tả'),
                  leading: CircleAvatar(
                    backgroundColor: isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                    child: Icon(
                      isActive ? Icons.check_circle : Icons.cancel, 
                      color: isActive ? AppTheme.successColor : AppTheme.errorColor
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showSubjectDialog(sub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () => _confirmDelete(sub['id'], sub['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm môn học'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
