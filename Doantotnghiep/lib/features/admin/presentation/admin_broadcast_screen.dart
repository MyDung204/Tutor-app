import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/admin/data/admin_repository.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';

class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _targetRole = 'all'; // 'all', 'tutor', 'student'
  bool _isLoading = false;

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repo = ref.read(adminRepositoryProvider);
    final data = {
      'title': _titleCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
      'target_role': _targetRole,
    };

    final success = await repo.sendBroadcast(data);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi thông báo thành công')));
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() => _targetRole = 'all');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi thất bại')));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo nền tảng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gửi thông báo mới',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Thông báo sẽ được gửi qua Cloud Messaging / In-app cho các người dùng thuộc diện được chọn.'),
              const SizedBox(height: 32),

              DropdownButtonFormField<String>(
                value: _targetRole,
                decoration: const InputDecoration(labelText: 'Đối tượng nhận', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả người dùng')),
                  DropdownMenuItem(value: 'tutor', child: Text('Chỉ Gia Sư')),
                  DropdownMenuItem(value: 'student', child: Text('Chỉ Học Viên')),
                ],
                onChanged: (val) => setState(() => _targetRole = val ?? 'all'),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề thông báo (*)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _bodyCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Nội dung chi tiết (*)', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendBroadcast,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Đang gửi...' : 'Phát Thông Báo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
