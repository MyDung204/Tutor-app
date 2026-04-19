import 'package:doantotnghiep/features/group/data/group_request_provider.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  final GroupRequest? group;
  const CreateGroupScreen({super.key, this.group});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _maxMembersController = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _topicController.text = widget.group!.topic;
      _subjectController.text = widget.group!.subject;
      _gradeController.text = widget.group!.gradeLevel;
      _locationController.text = widget.group!.location;
      _priceController.text = widget.group!.pricePerSession.toInt().toString();
      _descController.text = widget.group!.description;
      _maxMembersController.text = widget.group!.maxMembers.toString();
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _subjectController.dispose();
    _gradeController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.group != null ? 'Chỉnh sửa nhóm' : 'Tạo nhóm học mới', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFf3e7e9), Color(0xFFe3eeff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Thông tin nhóm'),
                    _buildTextField(
                      controller: _topicController,
                      label: 'Tiêu đề nhóm',
                      hint: 'VD: Tìm bạn cùng ôn thi Đại học...',
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _subjectController,
                      label: 'Môn học',
                      hint: 'VD: Toán, Tiếng Anh...',
                      icon: Icons.book_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _gradeController,
                      label: 'Trình độ / Lớp',
                      hint: 'VD: Lớp 5, IELTS 6.0...',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionTitle('Chi tiết tham gia'),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Khu vực / Hình thức',
                      hint: 'VD: Quận 3 hoặc Online',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Học phí dự kiến',
                            hint: 'VNĐ/buổi',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxMembersController,
                            label: 'Số lượng tối đa',
                            hint: 'VD: 3',
                            icon: Icons.group_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descController,
                      label: 'Mô tả thêm',
                      hint: 'Yêu cầu về giáo viên, lịch học mong muốn, mục tiêu khóa học...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      required: false,
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(widget.group != null ? 'Cập nhật nhóm' : 'Đăng tin tìm bạn học', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: required ? (value) => value!.isEmpty ? 'Vui lòng nhập $label' : null : null,
    );
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.group != null;
      final price = double.tryParse(_priceController.text) ?? 0;
      final maxMembers = int.tryParse(_maxMembersController.text) ?? 3;

      if (isEditing) {
        final success = await ref.read(sharedLearningRepositoryProvider).updateGroup(
          widget.group!.id,
          {
            'topic': _topicController.text,
            'subject': _subjectController.text,
            'grade_level': _gradeController.text,
            'price': price,
            'location': _locationController.text,
            'description': _descController.text,
            'max_members': maxMembers,
          }
        );

        if (success && mounted) {
           ref.invalidate(groupRequestsProvider);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Đã cập nhật nhóm thành công!'), backgroundColor: Colors.green),
           );
           // Navigate back and ideally signal refresh
           context.pop(true);
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Lỗi khi cập nhật nhóm. Vui lòng thử lại.')),
           );
        }
      } else {
        final newRequest = GroupRequest(
          id: '', 
          creatorId: '',
          creatorName: '',
          topic: _topicController.text,
          subject: _subjectController.text,
          gradeLevel: _gradeController.text,
          pricePerSession: price,
          location: _locationController.text,
          description: _descController.text,
          maxMembers: maxMembers,
          minMembers: 2,
          createdAt: DateTime.now(),
          startTime: DateTime.now().add(const Duration(days: 3)),
        );

        final newGroup = await ref.read(sharedLearningRepositoryProvider).createStudyGroup(newRequest);

        if (newGroup != null && mounted) {
          ref.refresh(groupRequestsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo nhóm thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pushReplacement('/group-management', extra: newGroup);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi tạo nhóm. Vui lòng thử lại.')),
          );
        }
      }
    }
  }
}
