/// Admin Users Screen
/// 
/// **Purpose:**
/// - Quản lý danh sách người dùng trong hệ thống
/// - Tìm kiếm, lọc và quản lý (Khóa/Mở khóa/Sửa)
/// 
/// **Design:**
/// - Data-Dense List View (Table-like rows)
/// - Clean Filter Bar
library;

import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:doantotnghiep/features/admin/data/admin_users_provider.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  String _selectedRole = 'All'; // All, Gia sư, Học viên

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(
      UserFilter(search: _searchQuery, role: _selectedRole),
    ));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && val == _searchQuery) return;
                      setState(() {
                        _searchQuery = val;
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Gia sư', 'Gia sư'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Học viên', 'Học viên'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // User List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 64, color: AppTheme.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy người dùng nào.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserRow(user);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRole == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
           setState(() => _selectedRole = value);
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
      ),
      backgroundColor: Colors.transparent,
    );
  }

  /// Build user row (Data-Dense style)
  Widget _buildUserRow(Map<String, dynamic> user) {
     final isTutor = user['role'] == 'tutor' || user['role'] == 'Gia sư';
     final isBanned = user['is_banned'] == true || user['status'] == 'banned'; 
     
     // Use first char for avatar if no image
     final firstChar = (user['name'] as String? ?? 'U').substring(0, 1).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ListTile(
        onTap: () => context.push('/admin/users/${user['id']}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isTutor ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            firstChar,
            style: TextStyle(
              color: isTutor ? AppTheme.warningColor : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'] ?? 'No Name',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isBanned)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 12, color: AppTheme.errorColor),
                    const SizedBox(width: 4),
                    Text(
                      'Đã khóa',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleBadge(isTutor),
                if (user['created_at'] != null) ...[
                   const SizedBox(width: 8),
                   Text(
                     '• ${DateFormat('dd/MM/yyyy').format(DateTime.parse(user['created_at']))}',
                     style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                   ),
                ]
              ],
            )
          ],
        ),
        trailing: _buildActionMenu(user, isBanned),
      ),
    );
  }

  Widget _buildRoleBadge(bool isTutor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isTutor ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isTutor ? 'Gia sư' : 'Học viên',
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold, 
          color: isTutor ? AppTheme.warningColor : AppTheme.primaryColor
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> user, bool isBanned) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text('Chỉnh sửa'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ban',
          child: Row(
            children: [
              Icon(isBanned ? Icons.lock_open : Icons.block, color: isBanned ? AppTheme.successColor : AppTheme.errorColor, size: 20),
              const SizedBox(width: 8),
              Text(isBanned ? 'Mở khóa' : 'Khóa'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'edit') {
           _showEditUserDialog(user);
        } else if (value == 'ban') {
          _confirmBan(user, isBanned);
        }
      },
    );
  }

  Future<void> _confirmBan(Map<String, dynamic> user, bool isBanned) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản'),
          content: Text(
            isBanned
                ? 'Mở khóa cho ${user['name']}?'
                : 'Khóa tài khoản của ${user['name']}? Người dùng sẽ không thể đăng nhập.',
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: isBanned ? AppTheme.successColor : AppTheme.errorColor,
              ),
              child: Text(isBanned ? 'Mở khóa' : 'Khóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await ref.read(adminRepositoryProvider).toggleBan(user['id']);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isBanned ? 'Đã mở khóa.' : 'Đã khóa.'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            ref.invalidate(adminUsersProvider(UserFilter(search: _searchQuery, role: _selectedRole)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi cập nhật.'), backgroundColor: AppTheme.errorColor),
            );
          }
        }
      }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final phoneController = TextEditingController(text: user['phone_number']);
    final addressController = TextEditingController(text: user['address']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa ${user['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ tên')),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              const SizedBox(height: 12),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Địa chỉ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final updatedData = {
                'name': nameController.text,
                'phone_number': phoneController.text,
                'address': addressController.text,
              };
              Navigator.pop(context);
              final success = await ref.read(adminRepositoryProvider).updateUser(user['id'], updatedData);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công'), backgroundColor: AppTheme.successColor));
                  ref.invalidate(adminUsersProvider(UserFilter(search: _searchQuery, role: _selectedRole)));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại'), backgroundColor: AppTheme.errorColor));
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
