import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorProfileEditScreen extends ConsumerStatefulWidget {
  final Tutor tutor;

  const TutorProfileEditScreen({super.key, required this.tutor});

  @override
  ConsumerState<TutorProfileEditScreen> createState() => _TutorProfileEditScreenState();
}

class _TutorProfileEditScreenState extends ConsumerState<TutorProfileEditScreen> {
  late TextEditingController _bioController;
  late TextEditingController _rateController;
  late TextEditingController _locationController;
  late TextEditingController _universityController;
  late TextEditingController _degreeController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.tutor.bio);
    _rateController = TextEditingController(text: widget.tutor.hourlyRate.toStringAsFixed(0));
    _locationController = TextEditingController(text: widget.tutor.location);
    _universityController = TextEditingController(text: widget.tutor.university);
    _degreeController = TextEditingController(text: widget.tutor.degree);
    _phoneController = TextEditingController(text: widget.tutor.phone);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _rateController.dispose();
    _locationController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // In a real app, we would use a repository to save these
      // Mocking the API call with all fields
      final data = {
        'bio': _bioController.text,
        'hourly_rate': double.tryParse(_rateController.text),
        'location': _locationController.text,
        'university': _universityController.text,
        'degree': _degreeController.text,
        'phone': _phoneController.text,
      };
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
        );
        context.pop(); // Back to Profile
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ gia sư'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Giới thiệu bản thân'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Mô tả kinh nghiệm, phương pháp giảng dạy...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập giới thiệu' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Giá tiền mỗi giờ (VNĐ)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 200000',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập giá';
                  if (double.tryParse(value) == null) return 'Giá tiền không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Địa điểm dạy'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Quận/Huyện, Thành phố',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập địa điểm' : null,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Môn học giảng dạy'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ...widget.tutor.subjects.map((s) => Chip(
                    label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    backgroundColor: EduTheme.primary,
                    onDeleted: () {}, 
                    deleteIconColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16, color: EduTheme.primary),
                    label: const Text('Thêm môn', style: TextStyle(color: EduTheme.primary, fontSize: 13)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: EduTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onPressed: () {}, 
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Thông tin bổ sung'),
              const SizedBox(height: 8),
              _buildTextField(_universityController, 'Trường đại học', Icons.school_outlined),
              const SizedBox(height: 12),
              _buildTextField(_degreeController, 'Bằng cấp/Chứng chỉ', Icons.workspace_premium_outlined),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Số điện thoại', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cập nhật ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: EduTheme.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
