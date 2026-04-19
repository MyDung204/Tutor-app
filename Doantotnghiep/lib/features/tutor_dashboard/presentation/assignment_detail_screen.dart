
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/assignment.dart';
import 'package:doantotnghiep/features/group/domain/models/course.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

final assignmentSubmissionsProvider = FutureProvider.family<List<AssignmentSubmission>, int>((ref, assignmentId) {
  return ref.watch(sharedLearningRepositoryProvider).getAssignmentSubmissions(assignmentId);
});

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final Assignment assignment;
  final bool isTutor;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.isTutor,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if student has submitted
    if (!widget.isTutor && widget.assignment.isSubmitted && widget.assignment.mySubmission != null) {
      _contentController.text = widget.assignment.mySubmission!.content ?? '';
      // We can't pre-fill file as File object, but we can show the URL in UI
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_contentController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung hoặc chọn ảnh.')));
      return;
    }

    setState(() => _isSubmitting = true);

    String? fileUrl;
    // Mock upload for now: In real app, upload _selectedImage to Firebase Storage and get URL
    if (_selectedImage != null) {
       // Simulate upload
       await Future.delayed(const Duration(seconds: 1)); 
       fileUrl = 'https://via.placeholder.com/300?text=Uploaded+Image'; 
       // In production using user's real logic, this would be:
       // fileUrl = await ref.read(chatRepositoryProvider).uploadImage(_selectedImage!);
    }

    final result = await ref.read(sharedLearningRepositoryProvider).submitAssignment(
      widget.assignment.id, 
      _contentController.text, 
      fileUrl
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Nộp bài thành công!')));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Lỗi khi nộp bài.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài tập'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (widget.isTutor) 
              _buildTutorView()
            else 
              _buildStudentView(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.assignment.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
         Text(
          'Ngày giao: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.assignment.createdAt)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        if (widget.assignment.dueDate != null) ...[
          const SizedBox(height: 4),
          Text(
            'Hạn nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.assignment.dueDate!)}',
            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.assignment.description != null && widget.assignment.description!.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.assignment.description!,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentView() {
    final hasSubmitted = widget.assignment.isSubmitted;
    final submission = widget.assignment.mySubmission;

    if (hasSubmitted && submission != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đã nộp bài', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(submission.submittedAt),
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Bài nộp của bạn:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (submission.content != null && submission.content!.isNotEmpty)
            Text(submission.content!),
          if (submission.fileUrl != null)
             Padding(
               padding: const EdgeInsets.only(top: 12),
               child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: submission.fileUrl!, 
                    height: 200, 
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                  ),
               ),
             ),
             
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Allow re-submission
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng nộp lại đang phát triển')));
              },
              child: const Text('Nộp lại'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nộp bài', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _contentController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung câu trả lời...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh'),
               style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            ),
          ],
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 12,
                      child: Icon(Icons.close, size: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: EduTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Nộp bài ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildTutorView() {
    final submissionsAsync = ref.watch(assignmentSubmissionsProvider(widget.assignment.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danh sách nộp bài', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        submissionsAsync.when(
          data: (submissions) {
            if (submissions.isEmpty) {
              return const Center(child: Text('Chưa có học viên nào nộp bài.'));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: submissions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final sub = submissions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: sub.student?.avatarUrl != null ? NetworkImage(sub.student!.avatarUrl!) : null,
                    child: sub.student?.avatarUrl == null ? Text(sub.student?.name[0] ?? '?') : null,
                  ),
                  title: Text(sub.student?.name ?? 'Học viên'),
                  subtitle: Text('Nộp lúc: ${DateFormat('HH:mm dd/MM').format(sub.submittedAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showSubmissionDetail(sub);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Lỗi: $err'),
        ),
      ],
    );
  }

  void _showSubmissionDetail(AssignmentSubmission sub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   CircleAvatar(
                    backgroundImage: sub.student?.avatarUrl != null ? NetworkImage(sub.student!.avatarUrl!) : null,
                    radius: 24,
                    child: sub.student?.avatarUrl == null ? Text(sub.student?.name[0] ?? '?') : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.student?.name ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Nộp lúc: ${DateFormat('HH:mm dd/MM/yyyy').format(sub.submittedAt)}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Nội dung:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (sub.content != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(sub.content!),
                ),
              if (sub.fileUrl != null)
                Padding(
                   padding: const EdgeInsets.symmetric(vertical: 12),
                   child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: sub.fileUrl!,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
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
