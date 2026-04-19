import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/group/data/group_request_provider.dart';
import 'package:doantotnghiep/features/chat/data/firebase_chat_repository.dart'; // Added
import 'package:doantotnghiep/features/chat/presentation/group_chat_screen.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart'; // Added

class GroupDetailScreen extends ConsumerStatefulWidget {
  final GroupRequest group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  late GroupRequest _group;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncGroupChatMembers();
    });
  }

  Future<void> _syncGroupChatMembers() async {
    // 1. Fetch current members from API
    final repo = ref.read(sharedLearningRepositoryProvider);
    final members = await repo.getGroupMembers(_group.id);
    
    // 2. Extract IDs
    // Assuming members list contains objects with 'pk' or 'id'
    // Let's inspect member structure if failed, but usually it has 'id'
    // Based on Controller, it returns User objects.
    
    final List<String> memberIds = [];
    if (members.isNotEmpty) {
      for (var m in members) {
         if (m is Map && m['id'] != null) {
           final status = m['status']?.toString() ?? 'pending';
           // Only add approved members or the creator
           if (status == 'approved' || status == 'member' || m['id'].toString() == _group.creatorId.toString()) {
              memberIds.add(m['id'].toString());
           }
         }
      }
    }
    
    // Add Creator ID just in case it's not in the list (though it should be)
    final creatorId = _group.creatorId;
    if (!memberIds.contains(creatorId)) {
      memberIds.add(creatorId);
    }

    // 3. Sync to Firestore
    await ref.read(firebaseChatRepositoryProvider).createOrUpdateGroupConversation(
      _group.id, 
      memberIds, 
      _group.topic
    );
  }

  Future<void> _refreshGroup() async {
    // Ideally fetch fresh data from API
    // For now, we rely on the passed object or could fetch by ID if API supported it
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời nhóm?'),
        content: const Text('Bạn có chắc chắn muốn rời khỏi nhóm này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await ref.read(sharedLearningRepositoryProvider).leaveGroup(_group.id);
        if (success) {
          // Sync Firestore: Remove myself from conservation group
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user != null) {
             await ref.read(firebaseChatRepositoryProvider).removeMemberFromGroupConversation(
               _group.id, 
               user.id.toString()
             );
          }

          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã rời nhóm thành công')));
             ref.invalidate(myJoinedGroupsProvider); // Refresh list
             context.pop();
          }
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi rời nhóm')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).value;
    final isCreator = user?.id == _group.creatorId;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nhóm'),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                 final updated = await context.push('/create-group', extra: _group);
                 if (updated == true) {
                    _refreshGroup();
                    ref.invalidate(groupRequestsProvider); // Ensure the list also refreshes
                 }
              },
            ),
          // Note: Members cannot leave - only creator can remove them via management
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_group.topic, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: EduTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(_group.subject, style: TextStyle(color: EduTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(_group.gradeLevel, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.calendar_today, 'Ngày bắt đầu:', DateFormat('dd/MM/yyyy').format(_group.startTime)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, 'Địa điểm:', _group.location),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.attach_money, 'Chi phí:', '${currencyFormat.format(_group.pricePerSession)}/buổi'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Mô tả', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_group.description.isNotEmpty ? _group.description : 'Không có mô tả', style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thành viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_group.currentMembers}/${_group.maxMembers}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            // Member List (Mock or Fetch)
              if (isCreator)
                Badge(
                  isLabelVisible: _group.pendingRequestsCount > 0,
                  label: Text('${_group.pendingRequestsCount}'),
                  backgroundColor: Colors.red,
                  offset: const Offset(-5, 5),
                  child: OutlinedButton.icon(
                    onPressed: () {
                       context.push('/group-management', extra: _group);
                    },
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Quản lý thành viên'),
                  ),
                )
            else
               const Text('Chỉ trưởng nhóm mới có thể xem danh sách chi tiết.'),
          ],
        ),
      ),
      bottomNavigationBar: !isCreator && (_group.membershipStatus == null || _group.membershipStatus == 'rejected') 
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]),
              child: ElevatedButton(
                onPressed: () {
                  // Join Request Logic (Reuse existing flow)
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: EduTheme.primary),
                child: const Text('Tham gia nhóm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
      // Floating Chat Bubble
      floatingActionButton: (isCreator || _group.membershipStatus == 'approved' || _group.membershipStatus == 'member')
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => GroupChatScreen(group: _group)),
                );
              },
              backgroundColor: EduTheme.primary,
              icon: StreamBuilder<DocumentSnapshot>(
                stream: ref.watch(firebaseChatRepositoryProvider).getGroupConversationStream(_group.id),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData && snapshot.data!.exists) {
                     final data = snapshot.data!.data() as Map<String, dynamic>;
                     final unreadMap = data['unread_counts'] as Map<String, dynamic>?;
                     final myId = ref.read(authRepositoryProvider).currentUser?.id.toString();
                     if (unreadMap != null && myId != null) {
                       unreadCount = unreadMap[myId] ?? 0;
                     }
                  }
                  
                  return Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    smallSize: 10,
                    backgroundColor: Colors.red,
                    offset: const Offset(4, -4),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                  );
                }
              ),
              label: const Text('Chat nhóm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
      ],
    );
  }
}
