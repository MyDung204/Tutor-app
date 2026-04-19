import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/core/network/api_client.dart'; 

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';

import 'package:doantotnghiep/features/tutor_dashboard/domain/models/tutor_request.dart';

class CreateTutorRequestScreen extends ConsumerStatefulWidget {
  final TutorRequest? requestToEdit;
  const CreateTutorRequestScreen({super.key, this.requestToEdit});

  @override
  ConsumerState<CreateTutorRequestScreen> createState() => _CreateTutorRequestScreenState();
}

class _CreateTutorRequestScreenState extends ConsumerState<CreateTutorRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.requestToEdit != null) {
      final req = widget.requestToEdit!;
      _subjectController.text = req.subject;
      _gradeController.text = req.gradeLevel;
      _minBudgetController.text = req.minBudget.toStringAsFixed(0);
      _maxBudgetController.text = req.maxBudget.toStringAsFixed(0);
      _scheduleController.text = req.schedule;
      _locationController.text = req.location;
      _descController.text = req.description;
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final apiClient = ref.read(apiClientProvider);
        final data = {
          'subject': _subjectController.text.trim(),
          'grade_level': _gradeController.text.trim(),
          'min_budget': double.tryParse(_minBudgetController.text.trim()) ?? 0,
          'max_budget': double.tryParse(_maxBudgetController.text.trim()) ?? 0,
          'schedule': _scheduleController.text.trim(),
          'location': _locationController.text.trim(),
          'description': _descController.text.trim().isEmpty 
              ? 'Không có mô tả thêm' 
              : _descController.text.trim(),
        };

        if (widget.requestToEdit != null) {
          // Update existing request
          await apiClient.put('/tutor-requests/${widget.requestToEdit!.id}', data: data);
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật yêu cầu thành công!')),
            );
          }
        } else {
          // Create new request
          await apiClient.post('/tutor-requests', data: data);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng yêu cầu thành công!')),
            );
          }
        }

        if (mounted) {
          ref.invalidate(tutorRequestsProvider);
          ref.invalidate(myTutorRequestsProvider);
          context.pop();
        }
      } catch (e) {
         if (mounted) {
           print('Error submitting request: $e');
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
         }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.requestToEdit != null ? 'Cập nhật yêu cầu' : 'Đăng yêu cầu tìm gia sư')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _subjectController.text.isNotEmpty && ['Toán', 'Lý', 'Hóa', 'Tiếng Anh', 'Văn', 'Sinh', 'Sử', 'Địa', 'Tin học', 'Piano', 'Guitar'].contains(_subjectController.text) 
                    ? _subjectController.text 
                    : null,
                items: ['Toán', 'Lý', 'Hóa', 'Tiếng Anh', 'Văn', 'Sinh', 'Sử', 'Địa', 'Tin học', 'Piano', 'Guitar']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _subjectController.text = v!),
                decoration: const InputDecoration(labelText: 'Môn học', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Chọn môn học' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gradeController.text.isNotEmpty && ['Lớp 1', 'Lớp 2', 'Lớp 3', 'Lớp 4', 'Lớp 5', 'Lớp 6', 'Lớp 7', 'Lớp 8', 'Lớp 9', 'Lớp 10', 'Lớp 11', 'Lớp 12', 'Đại học', 'Người đi làm'].contains(_gradeController.text) 
                    ? _gradeController.text 
                    : null,
                items: ['Lớp 1', 'Lớp 2', 'Lớp 3', 'Lớp 4', 'Lớp 5', 'Lớp 6', 'Lớp 7', 'Lớp 8', 'Lớp 9', 'Lớp 10', 'Lớp 11', 'Lớp 12', 'Đại học', 'Người đi làm']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gradeController.text = v!),
                decoration: const InputDecoration(labelText: 'Trình độ lớp', border: OutlineInputBorder()),
                 validator: (v) => v == null || v.isEmpty ? 'Chọn lớp' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ngân sách từ (VNĐ)', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty == true ? 'Nhập số tiền' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxBudgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Đến (VNĐ)', border: OutlineInputBorder()),
                      validator: (v) => v?.isEmpty == true ? 'Nhập số tiền' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(labelText: 'Thời gian học (VD: Tối 2-4-6)', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập thời gian' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Địa điểm / Hình thức (VD: Online, Quận 1)', border: OutlineInputBorder()),
                validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập địa điểm' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Yêu cầu thêm (VD: Sinh viên Bách Khoa...)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.requestToEdit != null ? 'Cập nhật' : 'Đăng tin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
