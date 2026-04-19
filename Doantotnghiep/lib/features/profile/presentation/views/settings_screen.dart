import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/notification/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doantotnghiep/features/map/presentation/location_picker_screen.dart';
import 'package:doantotnghiep/features/verification/presentation/verification_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.value;
    final isTutor = user?.role == 'tutor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildsectionHeader(context, 'Tài khoản'),
          _buildListTile(context, Icons.lock_outline, 'Đổi mật khẩu', () {
             context.push('/change-password');
          }),
          
          if (isTutor)
            _buildListTile(context, Icons.verified_user_outlined, 'Xác thực tài khoản', () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VerificationScreen()));
            }, subtitle: 'Nộp giấy tờ xác minh danh tính'),
          
          if (isTutor)
             _buildListTile(context, Icons.location_on_outlined, 'Cập nhật vị trí hiển thị', () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
             }, subtitle: 'Căn chỉnh vị trí trên bản đồ để học viên tìm thấy bạn'),

          _buildListTile(context, Icons.language, 'Ngôn ngữ', () {}, subtitle: 'Tiếng Việt'),
          _buildSwitchTile(context, Icons.notifications_none, 'Thông báo', true, (val) {}),
          _buildListTile(context, Icons.notification_important_rounded, 'Kiểm tra thông báo (Test)', () async {
              final user = ref.read(authRepositoryProvider).currentUser;
              if (user != null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang gửi test...')));
                try {
                   await ref.read(notificationRepositoryProvider).sendTestNotification(user.id);
                   // Success message handled by push up if works, but let's show success
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
          }, iconColor: Colors.deepPurple, textColor: Colors.deepPurple),
          
          const Divider(height: 32),
          _buildsectionHeader(context, 'Ứng dụng'),
          _buildListTile(context, Icons.info_outline, 'Về chúng tôi', () {}),
          _buildListTile(context, Icons.privacy_tip_outlined, 'Chính sách bảo mật', () {}),
          _buildListTile(context, Icons.description_outlined, 'Điều khoản sử dụng', () {}),
          
          const Divider(height: 32),
          _buildListTile(context, Icons.delete_forever, 'Xóa tài khoản', () {
             // TODO: Implement Delete Account
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng liên hệ Admin để xóa tài khoản')));
          }, textColor: Colors.red, iconColor: Colors.red),
          
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Phiên bản 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildsectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, 
    IconData icon, 
    String title, 
    VoidCallback onTap, 
    {String? subtitle, Color? textColor, Color? iconColor}
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(title, style: TextStyle(color: textColor ?? Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, 
    IconData icon, 
    String title, 
    bool value, 
    ValueChanged<bool> onChanged
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: Switch(
        value: value,
        activeThumbColor: Theme.of(context).primaryColor,
        onChanged: onChanged,
      ),
    );
  }
}
