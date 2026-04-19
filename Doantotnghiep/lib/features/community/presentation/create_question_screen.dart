
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/community/data/community_provider.dart';
import 'package:doantotnghiep/features/community/domain/models/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  ConsumerState<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends ConsumerState<CreateQuestionScreen> {
  final _contentCtrl = TextEditingController();
  String _selectedSubject = 'Toán';
  final List<String> _subjects = ['Toán', 'Lý', 'Hóa', 'Văn', 'Anh', 'Khác'];

  void _postQuestion() {
    if (_contentCtrl.text.isEmpty) return;
    
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đặt câu hỏi!')));
       return;
    }

    final newQ = Question(
      id: const Uuid().v4(),
      userId: user.id,
      userName: user.name,
      userAvatar: user.avatarUrl ?? 'https://i.pravatar.cc/150',
      subject: _selectedSubject,
      content: _contentCtrl.text,
      createdAt: DateTime.now(),
    );

    ref.read(communityProvider.notifier).addQuestion(newQ);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang đăng câu hỏi...')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt câu hỏi', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _postQuestion,
            child: const Text('Đăng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Môn học:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedSubject,
                  items: _subjects.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val!),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Bạn đang thắc mắc vấn đề gì?',
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.camera_alt, color: Colors.blue), onPressed: () {}),
                  const Spacer(),
                  const Text('Thêm ảnh minh họa', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 8),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
