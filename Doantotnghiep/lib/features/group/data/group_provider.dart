
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/wallet/data/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupNotifier extends Notifier<List<GroupRequest>> {
  @override
  List<GroupRequest> build() {
    // Mock Data
    return [
      GroupRequest(
        id: '1',
        creatorId: 'user1',
        creatorName: 'Nguyễn Văn A',
        subject: 'Tiếng Anh Giao Tiếp',
        gradeLevel: 'Sinh viên',
        pricePerSession: 50000,
        location: 'Q. Cầu Giấy',
        description: 'Cần tìm 3 bạn học chung để share tiền gia sư.',
        currentMembers: 4,
        maxMembers: 5,
        minMembers: 4,
        startTime: DateTime.now().add(const Duration(hours: 20)), // Starts in 20h (<24h -> Locked)
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'full',
      ),
       GroupRequest(
        id: '2',
        creatorId: 'user2',
        creatorName: 'Trần Thị B',
        subject: 'Toán 12',
        gradeLevel: 'Lớp 12',
        pricePerSession: 150000,
        location: 'Online',
        description: 'Ôn thi đại học cấp tốc.',
        currentMembers: 2,
        maxMembers: 5,
        minMembers: 3,
        startTime: DateTime.now().add(const Duration(days: 3)), // > 24h -> Open
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'open',
      ),
    ];
  }

  // Join Group with Pre-Authorization Mock
  void joinGroup(String groupId, String userId) {
    // 1. Check if group exists and is open
    // 2. Pre-authorize deposit (Mock)
    state = [
      for (final g in state)
        if (g.id == groupId)
          g.copyWith(currentMembers: g.currentMembers + 1)
        else
          g
    ];
  }

  // Leave Group with Penalty Logic
  String leaveGroup(String groupId, String userId, WidgetRef ref) {
    final group = state.firstWhere((g) => g.id == groupId);
    
    final now = DateTime.now();
    final hoursUntilStart = group.startTime.difference(now).inHours;

    if (hoursUntilStart < 24) {
      // PENALTY CASE: Late cancellation
      // 1. User loses deposit (Mock deduction from Wallet)
      // 2. Tutor receives compensation
      
      final penaltyAmount = group.pricePerSession; // Lose 1 session cost

      ref.read(walletProvider.notifier).addTransaction(Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Phạt hủy nhóm muộn ($groupId)',
        amount: penaltyAmount,
        date: DateTime.now(),
        type: 'debit',
      ));

      // Remove member but Group Status might NOT change to 'open' if we want to keep it running for others
      // OR we reduce member count but keep price same for others (since Tutor got compensated)
       state = [
        for (final g in state)
          if (g.id == groupId)
            g.copyWith(currentMembers: g.currentMembers - 1)
          else
            g
      ];
      
      return "Bạn đã hủy nhóm quá muộn (<24h). Phí cọc $penaltyAmountđ đã được chuyển cho Gia sư để bù lỗ.";
    } else {
      // Normal cancellation
       state = [
        for (final g in state)
          if (g.id == groupId)
            g.copyWith(currentMembers: g.currentMembers - 1)
          else
            g
      ];
      return "Đã rời nhóm thành công. Tiền cọc đã được giải tỏa.";
    }
  }
}

final groupProvider = NotifierProvider<GroupNotifier, List<GroupRequest>>(GroupNotifier.new);
