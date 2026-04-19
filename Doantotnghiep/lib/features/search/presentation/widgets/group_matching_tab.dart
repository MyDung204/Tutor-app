import 'package:doantotnghiep/features/group/data/group_request_provider.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/group/data/shared_learning_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';

/// Group Matching Tab - Tab "Học ghép" trong Search Screen
/// 
/// **Purpose:**
/// - Hiển thị danh sách các nhóm học tập (Study Groups)
/// - Cho phép học viên tạo nhóm mới hoặc tham gia nhóm có sẵn
/// - Quản lý trạng thái tham gia (pending, approved, rejected)
/// 
/// **Features:**
/// - Tạo nhóm học mới
/// - Xem danh sách nhóm
/// - Tham gia nhóm (gửi yêu cầu)
/// - Kiểm tra nhóm (cho chủ nhóm)
/// - Hiển thị trạng thái: Đang chờ duyệt, Đã tham gia, Bị từ chối, Nhóm đã đầy
/// 
/// **Status Flow:**
/// - Không tham gia → "Tham gia nhóm" (gửi yêu cầu)
/// - Đã gửi yêu cầu → "Đang chờ duyệt" (pending)
/// - Được duyệt → "Đã tham gia" (approved)
/// - Bị từ chối → "Bị từ chối" (rejected)
/// - Chủ nhóm → "Kiểm tra nhóm" (quản lý thành viên)

class GroupMatchingTab extends ConsumerWidget {
  const GroupMatchingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(groupRequestsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final currentUser = ref.watch(authStateChangesProvider).value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/create-group'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tạo nhóm học mới'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
            ),
          ),
        ),
        Expanded(
          child: requestsAsync.when(
            skipLoadingOnRefresh: true,
            data: (requests) {
              // Exclude user's own groups from the search list
              final displayRequests = requests.where((req) => 
                  currentUser == null || currentUser.id.toString() != req.creatorId.toString()
              ).toList();

              if (displayRequests.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(groupRequestsProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text("Chưa có nhóm nào.", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  return ref.refresh(groupRequestsProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displayRequests.length,
                  itemBuilder: (context, index) => _buildGroupCard(context, displayRequests[index], currencyFormat, ref),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
          ),
        ),
      ],
    );
  }

  /// Build group card widget
  /// 
  /// **Purpose:**
  /// - Hiển thị thông tin nhóm học tập
  /// - Xác định trạng thái tham gia của user
  /// - Hiển thị button phù hợp với trạng thái
  /// 
  /// **Parameters:**
  /// - `context`: BuildContext
  /// - `req`: GroupRequest object
  /// - `currencyFormat`: NumberFormat for currency display
  /// - `ref`: WidgetRef for Riverpod
  /// 
  /// **Button States:**
  /// - Owner: "Kiểm tra nhóm" → Navigate to group management
  /// - Approved: "Đã tham gia" (disabled)
  /// - Pending: "Đang chờ duyệt" (disabled, tonal style)
  /// - Rejected: "Bị từ chối" (disabled, red style)
  /// - Full: "Nhóm đã đầy" (disabled, tonal style)
  /// - Available: "Tham gia nhóm" → Show join confirmation
  Widget _buildGroupCard(BuildContext context, GroupRequest req, NumberFormat currencyFormat, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    // Check if current user is the group creator
    final isOwner = user != null && user.id.toString() == req.creatorId.toString();
    // Check if group is full
    final isFull = req.currentMembers >= req.maxMembers;
    // Check membership status (pending, approved, rejected)
    final isPending = req.membershipStatus == 'pending';
    final isApproved = req.membershipStatus == 'approved';
    final isRejected = req.membershipStatus == 'rejected';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFull ? 'Đã đầy' : 'Đang chờ: ${req.currentMembers}/${req.maxMembers} HS',
                    style: TextStyle(color: isFull ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  '${currencyFormat.format(req.pricePerSession)}/buổi',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${req.subject} - ${req.gradeLevel}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Tạo bởi: ${isOwner ? 'Bạn' : req.creatorName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (isOwner && req.pendingRequestsCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${req.pendingRequestsCount} yêu cầu',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
            const SizedBox(height: 8),
            Text(
              req.description,
              style: const TextStyle(color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
               children: [
                 const Icon(Icons.location_on_outlined, size: 14, color: Colors.blueGrey),
                 const SizedBox(width: 4),
                  Text(req.location, style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500)),
               ],
            ),
            const SizedBox(height: 16),
            // Action Button - Different states based on user's relationship with group
            // Logic: Owner → Check Group | Approved → Joined | Pending → Waiting | Rejected → Rejected | Full → Full | Available → Join
            SizedBox(
              width: double.infinity,
              child: isOwner 
                // Owner: Navigate to group management screen to approve/reject members
                ? FilledButton.icon(
                    onPressed: () {
                         _showGroupManagement(context, req);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Kiểm tra nhóm'),
                  )
                // Member status: Approved (already joined)
                : isApproved
                    ? const FilledButton(onPressed: null, child: Text('Đã tham gia'))
                // Member status: Pending (waiting for approval)
                : isPending
                    ? const FilledButton.tonal(onPressed: null, child: Text('Đang chờ duyệt'))
                // Member status: Rejected (request was rejected)
                : isRejected
                     ? OutlinedButton(
                         onPressed: () {
                           _showJoinConfirmation(context, req, ref);
                         },
                         style: OutlinedButton.styleFrom(
                           side: const BorderSide(color: Colors.orange),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           foregroundColor: Colors.orange,
                         ),
                         child: const Text('Xin vào lại'),
                       )
                // Group is full (cannot join)
                : isFull 
                    ? const FilledButton.tonal(
                        onPressed: null, 
                        child: Text('Nhóm đã đầy'),
                      )
                // Available: Show join confirmation dialog
                : OutlinedButton(
                    onPressed: () {
                      _showJoinConfirmation(context, req, ref);
                    },
                    style: OutlinedButton.styleFrom(
                       side: const BorderSide(color: Colors.blueAccent),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       foregroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Tham gia nhóm'),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show join confirmation dialog
  /// 
  /// **Purpose:**
  /// - Confirms user's intent to join a study group
  /// - Sends join request to backend
  /// - Updates UI after successful join
  /// 
  /// **Process:**
  /// 1. Show confirmation dialog
  /// 2. If confirmed, call repository to join group
  /// 3. Invalidate provider to refresh list
  /// 4. Show success/error message
  void _showJoinConfirmation(BuildContext context, GroupRequest req, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tham gia'),
        content: Text('Bạn có chắc chắn muốn tham gia nhóm "${req.subject}" này không?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(sharedLearningRepositoryProvider);
              final success = await repo.joinGroup(req.id);
              if (success) {
                  ref.invalidate(groupRequestsProvider);
                  ref.invalidate(myAllGroupsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã gửi yêu cầu tham gia thành công!')),
                    );
                  }
              } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gửi yêu cầu thất bại. Vui lòng thử lại.')),
                    );
                  }
              }
            },
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  /// Navigate to group management screen
  /// 
  /// **Purpose:**
  /// - Opens group management screen for group owner
  /// - Allows owner to approve/reject pending members
  /// - Shows list of all group members
  /// 
  /// **Features in Group Management:**
  /// - View all members (approved, pending, rejected)
  /// - Approve pending members
  /// - Reject pending members
  /// - Remove members (for approved members)
  /// - Delete group
  void _showGroupManagement(BuildContext context, GroupRequest req) {
       context.push('/group-management', extra: req);
  }
}
