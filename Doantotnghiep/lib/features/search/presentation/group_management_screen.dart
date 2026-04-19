import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/features/chat/data/firebase_chat_repository.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  final GroupRequest group;

  const GroupManagementScreen({super.key, required this.group});

  @override
  ConsumerState<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    final repo = ref.read(sharedLearningRepositoryProvider);
    final members = await repo.getGroupMembers(widget.group.id);
    if (mounted) {
      setState(() {
        _members = members;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveMember(String userId) async {
    final repo = ref.read(sharedLearningRepositoryProvider);
    final success = await repo.approveMember(widget.group.id, userId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt thành viên')));
      }
      _fetchMembers();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi duyệt')));
      }
    }
  }

  Future<void> _rejectMember(String userId) async {
    final repo = ref.read(sharedLearningRepositoryProvider);
    final success = await repo.rejectMember(widget.group.id, userId);
    if (success) {
      // Sync Firestore: Remove from conservation group just in case they were in it previously
      await ref.read(firebaseChatRepositoryProvider).removeMemberFromGroupConversation(
        widget.group.id, 
        userId
      );

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối thành viên')));
      _fetchMembers();
    }
  }

  Future<void> _removeMember(String userId) async {
     final confirmed = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Xác nhận'),
         content: const Text('Bạn có chắc muốn mời thành viên này ra khỏi nhóm?'),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đồng ý')),
         ],
       ),
     );
     if (confirmed != true) return;

    final repo = ref.read(sharedLearningRepositoryProvider);
    final success = await repo.removeMember(widget.group.id, userId);
    if (success) {
      // Sync Firestore: Remove from conservation group
      await ref.read(firebaseChatRepositoryProvider).removeMemberFromGroupConversation(
        widget.group.id, 
        userId
      );

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã mời ra khỏi nhóm')));
      _fetchMembers();
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Xác nhận giải tán'),
         content: const Text('Hành động này không thể hoàn tác. Bạn chắc chắn muốn xóa nhóm?'),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
           TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Xóa nhóm')),
         ],
       ),
     );
     if (confirmed != true) return;

     final repo = ref.read(sharedLearningRepositoryProvider);
     final success = await repo.deleteGroup(widget.group.id);
     if (success) {
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã giải tán nhóm')));
           Navigator.pop(context); // Back to list
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhóm'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _deleteGroup();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('Giải tán nhóm', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupInfoCard(),
              const SizedBox(height: 24),
              const Text(
                'Danh sách thành viên',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty
                      ? const Center(child: Text('Chưa có thành viên nào tham gia'))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _members.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            final status = member['status'] ?? 'pending';
                            final isMe = member['id'].toString() == widget.group.creatorId;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.grey),
                              ),
                              title: Text(member['name'] + (isMe ? ' (Bạn)' : '')),
                              subtitle: Text(
                                'Tham gia: ${_formatDate(member['joined_at'])}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   if (status == 'pending') ...[
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => _approveMember(member['id'].toString()),
                                        tooltip: 'Duyệt',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _rejectMember(member['id'].toString()),
                                        tooltip: 'Từ chối',
                                      ),
                                   ]
                                   else if (status == 'rejected')
                                      const Chip(
                                        label: Text('Đã từ chối', style: TextStyle(fontSize: 12, color: Colors.white)),
                                        backgroundColor: Colors.redAccent,
                                      )
                                   else if (!isMe)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => _removeMember(member['id'].toString()),
                                        tooltip: 'Mời ra khỏi nhóm',
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Chủ đề: ${widget.group.topic}'),
            const SizedBox(height: 4),
            Text('Thành viên: ${widget.group.currentMembers}/${widget.group.maxMembers}'),
            const SizedBox(height: 4),
            Text('Học phí: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.group.pricePerSession)}/buổi'),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
