/// Create Class Screen
/// 
/// **Purpose:**
/// - Tạo hoặc chỉnh sửa lớp học (1-1 hoặc nhóm)
/// - Cho phép gia sư thiết lập thông tin lớp học chi tiết
/// 
/// **Features:**
/// - Tạo lớp mới: 1-1 hoặc nhóm
/// - Chỉnh sửa lớp: Cập nhật thông tin lớp đã tạo
/// - Form validation: Kiểm tra các trường bắt buộc
/// - Date picker: Chọn ngày bắt đầu
/// 
/// **Form Fields:**
/// - Tên lớp học (required)
/// - Môn học (required)
/// - Lớp/Khối (required)
/// - Mô tả chi tiết (required)
/// - Học phí (required)
/// - Số lượng tối đa (required, default: 1 cho 1-1, 5 cho nhóm)
/// - Lịch học (required)
/// - Hình thức: Online/Offline (required)
/// - Địa điểm học (required nếu Offline)
/// - Ngày bắt đầu (required)
/// 
/// **Submit Flow:**
/// 1. Validate form
/// 2. Gọi API create/update course
/// 3. Refresh providers
/// 4. Navigate to class detail hoặc back
library;

import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/data/course_provider.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/my_classes_screen.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_class_provider.dart';
import 'package:doantotnghiep/core/exceptions/app_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/tutor_dashboard/presentation/widgets/schedule_picker_modal.dart';

/// Màn hình tạo/chỉnh sửa lớp học
/// 
/// **Usage:**
/// - Tạo mới: Từ dashboard → "Mở lớp 1-1" hoặc "Mở lớp nhóm"
/// - Chỉnh sửa: Từ class detail → Click icon edit
/// 
/// **Parameters:**
/// - `classToEdit`: Course object nếu đang chỉnh sửa (null nếu tạo mới)
/// - `isGroup`: true nếu là lớp nhóm, false nếu là lớp 1-1
class CreateClassScreen extends ConsumerStatefulWidget {
  final Course? classToEdit;
  final bool isGroup;

  const CreateClassScreen({super.key, this.classToEdit, this.isGroup = false});

  @override
  ConsumerState<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends ConsumerState<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  String _mode = 'Offline';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classToEdit != null) {
      final c = widget.classToEdit!;
      _titleController.text = c.title;
      _subjectController.text = c.subject;
      _gradeLevelController.text = c.gradeLevel;
      _descriptionController.text = c.description;
      _priceController.text = c.price.toStringAsFixed(0);
      _maxStudentsController.text = c.maxStudents.toString();
      _scheduleController.text = c.schedule;
      _mode = c.mode;
      if (c.address != null) _addressController.text = c.address!;
      _startDate = c.startDate;
    } else if (widget.isGroup) {
      _maxStudentsController.text = '5'; // Default for group
    } else {
      _maxStudentsController.text = '1'; // Default for 1-on-1
    }
  }

  /// Submit form để tạo hoặc cập nhật lớp học
  /// 
  /// **Purpose:**
  /// - Validate form trước khi submit
  /// - Gọi API để create/update course
  /// - Refresh providers và navigate
  /// 
  /// **Process:**
  /// 1. Validate form (nếu fail thì return)
  /// 2. Set loading state
  /// 3. Prepare data object
  /// 4. Call API (create hoặc update)
  /// 5. Refresh providers
  /// 6. Show success/error message
  /// 7. Navigate
  Future<void> _submit() async {
    // Validate form trước khi submit
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'title': _titleController.text,
      'subject': _subjectController.text,
      'grade_level': _gradeLevelController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'max_students': int.parse(_maxStudentsController.text),
      'schedule': _scheduleController.text,
      'mode': _mode,
      'address': _mode == 'Offline' ? _addressController.text : '',
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
    };

    final repo = ref.read(sharedLearningRepositoryProvider);

    if (widget.classToEdit != null) {
       final success = await repo.updateCourse(widget.classToEdit!.id, data);
       if (mounted) {
         if (success) {
           ref.invalidate(coursesProvider);
           ref.invalidate(myCoursesProvider);
           ref.invalidate(tutorClassProvider);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật lớp học!')));
           context.pop();
         } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra.')));
         }
       }
    } else {
       try {
         final newCourse = await repo.createCourse(data);
         if (mounted) {
           if (newCourse != null) {
             ref.invalidate(coursesProvider);
             ref.invalidate(myCoursesProvider);
             ref.invalidate(tutorClassProvider);
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Tạo lớp học thành công!'),
                 backgroundColor: Colors.green,
               ),
             );
             context.pushReplacement('/class-detail', extra: newCourse);
           } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Có lỗi xảy ra. Vui lòng thử lại.'),
                 backgroundColor: Colors.red,
               ),
             );
           }
         }
       } on ApiException catch (e) {
         // Hiển thị lỗi từ API (validation, unauthorized, etc.)
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(e.userMessage),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 4),
             ),
           );
         }
       } catch (e) {
         // Lỗi không mong đợi
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Lỗi: ${e.toString()}'),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 4),
             ),
           );
         }
       }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.classToEdit != null 
        ? 'Cập nhật lớp học' 
        : 'Mở lớp học';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên lớp học', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên lớp' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(labelText: 'Môn học', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Nhập môn' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _gradeLevelController,
                      decoration: const InputDecoration(labelText: 'Lớp (Khối)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Nhập khối' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Học phí (VND)', border: OutlineInputBorder(), suffixText: 'đ'),
                      validator: (v) => v == null || v.isEmpty ? 'Nhập học phí' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxStudentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng tối đa', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Nhập SL' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Lịch học',
                  hintText: 'Chọn lịch học...',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn lịch học' : null,
                onTap: () async {
                   final result = await showModalBottomSheet<String>(
                     context: context,
                     isScrollControlled: true,
                     builder: (context) => SchedulePickerModal(initialSchedule: _scheduleController.text),
                   );
                   if (result != null) {
                     _scheduleController.text = result;
                   }
                },
              ),
               const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _mode,
                decoration: const InputDecoration(labelText: 'Hình thức', border: OutlineInputBorder()),
                items: ['Online', 'Offline'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _mode = val!),
              ),
              if (_mode == 'Offline') ...[
                 const SizedBox(height: 16),
                 TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Địa điểm học', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập địa điểm' : null,
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Ngày bắt đầu dự kiến'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.grey)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.classToEdit != null ? 'Lưu thay đổi' : 'Tạo lớp học'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
