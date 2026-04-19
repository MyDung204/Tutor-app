/// Tutor Dashboard Screen - Enhanced Version
/// 
/// **Features:**
/// - Rich Stats Grid (6 metrics)
/// - Quick Action Grid (8 actions)
/// - Today's Schedule with action buttons
/// - Performance insights
/// - Recent activities
library;

import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_class_provider.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';
import 'package:doantotnghiep/features/notification/presentation/providers/notification_provider.dart';

import 'package:doantotnghiep/core/theme/edu_theme.dart';

import 'package:doantotnghiep/features/notification/domain/models/app_notification.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:doantotnghiep/features/chat/domain/models/conversation.dart';
import 'package:doantotnghiep/core/widgets/edu_marquee.dart';
import 'dart:async';

class TutorDashboardScreen extends ConsumerStatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  ConsumerState<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends ConsumerState<TutorDashboardScreen> {
  StreamSubscription? _notificationSubscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Listen to real-time notifications
    final notificationService = ref.read(notificationServiceProvider);
    _notificationSubscription = notificationService.onMessageReceived.listen((message) {
      if (mounted) {
        // Refresh all data when notification arrives
        ref.invalidate(tutorClassProvider);
        ref.invalidate(tutorRequestsProvider);
        ref.invalidate(bookingProvider);
        ref.invalidate(unreadNotificationCountProvider);
        
        // Show snackbar (Verified: this helps debugging)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có dữ liệu mới! Đang cập nhật...'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: EduTheme.success,
          ),
        );
      }
    });

    // Force Sync FCM Token to ensure backend has it (Fix for "Not receiving notifications")
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authRepositoryProvider).syncFCMToken();
    });

    // POLLING FALLBACK: Refresh data every 15 seconds (Reduced frequency to prevent flickering & errors)
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        ref.invalidate(bookingProvider);
        ref.invalidate(tutorRequestsProvider);
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(notificationsProvider); // Essential for "Smart Content" listener
        // Note: No snackbar here to avoid spamming usage
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Global Chat Notification Listener
    final activePartnerId = ref.watch(currentActivePartnerIdProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    
    ref.listen<AsyncValue<List<Conversation>>>(conversationsStreamProvider, (previous, next) {
      if (next.hasValue && previous?.hasValue == true) {
        final prevList = previous!.value!;
        final nextList = next.value!;
        final currentUser = ref.read(authRepositoryProvider).currentUser;

        for (var newConv in nextList) {
          final oldConv = prevList.firstWhere((c) => c.id == newConv.id, 
              orElse: () => Conversation(id: '-1', partnerId: '', partnerName: '', partnerAvatar: '', lastMessage: '', lastMessageTime: DateTime(2000), unreadCount: 0, lastSenderId: '0'));
          
          if (oldConv.id != '-1') {
              if (newConv.lastMessageTime.isAfter(oldConv.lastMessageTime) && newConv.lastMessage != oldConv.lastMessage) {
                if (newConv.lastSenderId != currentUser?.id) {
                    if (activePartnerId != newConv.partnerId) {
                      // SHOW POPUP using NotificationService
                      notificationService.showNotification(
                        title: 'Tin nhắn từ ${newConv.partnerName}',
                        body: newConv.lastMessage,
                      );
                    }
                }
              }
          }
        }
      }
    });

    // Listen to Notifications List to show SPECIFIC CONTENT
    ref.listen<AsyncValue<List<AppNotification>>>(notificationsProvider, (previous, next) {
      final prevList = previous?.valueOrNull ?? [];
      final nextList = next.valueOrNull ?? [];
      
      // If new data arrived and list is not empty
      if (nextList.isNotEmpty) {
        // Check if we have a new top item
        final newItem = nextList.first;
        final oldTopItem = prevList.isNotEmpty ? prevList.first : null;

        // If it's a new notification (different ID or just new)
        if (oldTopItem == null || newItem.id != oldTopItem.id) {
           // Wait! On first load, previous is null/empty. We don't want to blast notification on startup.
           // Only show if previous was NOT null (meaning this is a runtime update)
           // OR if the notification is remarkably new (e.g. created < 10 seconds ago)
           
           final isRecent = DateTime.now().difference(newItem.time).inSeconds < 15;
           
           // Logic: If runtime update (prev sent) OR very recent item found on sync
           if ((previous != null && prevList.isNotEmpty) || isRecent) {
              ref.read(notificationServiceProvider).showNotification(
                title: newItem.title,
                body: newItem.body,
              );
           }
        }
      }
    });

    final classesAsync = ref.watch(tutorClassProvider);
    final requestsAsync = ref.watch(tutorRequestsProvider);
    final bookingsAsync = ref.watch(bookingProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;

    final rating = user?.tutorProfile != null ? (user!.tutorProfile!['rating'] ?? 0.0).toString() : '0.0';

    return Scaffold(
      backgroundColor: EduTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/map'),
        child: const Icon(Icons.map_outlined),
        tooltip: 'Bản đồ',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh all data
            ref.invalidate(tutorClassProvider);
            ref.invalidate(tutorRequestsProvider);
            ref.invalidate(bookingProvider);
            ref.invalidate(authRepositoryProvider); // Refresh user profile (rating)
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll even if content is short
            slivers: [
              // Enhanced Header
              SliverToBoxAdapter(child: _buildEnhancedHeader(context, user, rating)),
              
              // Main Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats Grid (2x3)
                    _buildStatsGrid(rating),
                    const SizedBox(height: 24),
                    
                    // Booking Requests (NEW)
                    _buildBookingRequests(context, bookingsAsync),
                    const SizedBox(height: 24),

                    // Quick Actions Grid (4x2)
                    _buildQuickActionsGrid(context),
                    const SizedBox(height: 28),
                    
                    // Today's Schedule
                    _buildTodaySchedule(context, classesAsync),
                    const SizedBox(height: 28),
                    
                    // Performance Insights
                    _buildPerformanceInsights(),
                    const SizedBox(height: 28),
                    
                    // Recent Activities
                    _buildRecentActivities(),
                    const SizedBox(height: 28),
                    
                    // Student Requests Preview (Marketplace)
                    _buildStudentRequestsPreview(context, requestsAsync),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enhanced Header with Avatar, Rating, Location
  Widget _buildEnhancedHeader(BuildContext context, dynamic user, String rating) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EduTheme.primary, EduTheme.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl.isEmpty
                          ? Icon(Icons.person, size: 32, color: EduTheme.primary)
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: EduTheme.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Name and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào, Gia sư!',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'Gia sư',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                              const Text(' (28)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                              SizedBox(width: 2),
                              Text('Hà Nội', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Notifications
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
                        final unreadCount = unreadCountAsync.valueOrNull ?? 0;
                        if (unreadCount == 0) return const SizedBox.shrink();
                        
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: EduTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stats Grid 2x3
  Widget _buildStatsGrid(String rating) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildStatCard(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: EduTheme.success,
          title: 'Thu nhập',
          value: '2.5M đ',
          subtitle: '↑ +15%',
          trend: true,
        ),
        _buildStatCard(
          icon: Icons.school_rounded,
          iconColor: EduTheme.primary,
          title: 'Lớp đang dạy',
          value: '3',
          subtitle: 'Đang hoạt động',
        ),
        _buildStatCard(
          icon: Icons.people_rounded,
          iconColor: EduTheme.secondary,
          title: 'Học viên',
          value: '15',
          subtitle: 'Hiện tại',
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          title: 'Đánh giá',
          value: rating,
          subtitle: '(28 reviews)',
        ),
        _buildStatCard(
          icon: Icons.access_time_rounded,
          iconColor: EduTheme.purple,
          title: 'Giờ dạy',
          value: '24h',
          subtitle: 'Tháng này',
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          iconColor: Colors.teal,
          title: 'Tỉ lệ đặt',
          value: '85%',
          subtitle: '↑ +5%',
          trend: true,
        ),
      ],
    );
  }

  /// Booking Requests (From Students)
  Widget _buildBookingRequests(BuildContext context, AsyncValue<List<BookingItem>> bookingsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: EduTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded, size: 18, color: EduTheme.secondary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Yêu cầu đặt lịch',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        bookingsAsync.when(
          skipLoadingOnRefresh: true,
          data: (bookings) => _buildBookingRequestsList(bookings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) {
            // If we have stale data (which we should, because of skipLoadingOnRefresh), use it.
            // But skipLoadingOnRefresh only works during LOADING. If it fails, we get here.
            final staleData = bookingsAsync.valueOrNull;
            if (staleData != null && staleData.isNotEmpty) {
               return _buildBookingRequestsList(staleData);
            }
            return Text('Lỗi tải yêu cầu: Vui lòng kiểm tra kết nối', style: TextStyle(color: EduTheme.error));
          },
        ),
      ],
    );
  }

  Widget _buildBookingRequestsList(List<BookingItem> bookings) {
    // Filter: Locked (Pending) Only
    final requests = bookings.where((b) {
      final status = b.status.toLowerCase();
      return status == 'locked' || status == 'pending';
    }).toList();
    
    // Sort by date descending (newest first)
    requests.sort((a, b) => b.date.compareTo(a.date));

    if (requests.isEmpty) {
       return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: EduTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('Không có yêu cầu mới', style: TextStyle(color: EduTheme.textSecondary)),
        ),
      );
    }

    return Column(
      children: requests.take(3).map((booking) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EduTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EduTheme.primary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: EduTheme.primary.withValues(alpha: 0.1),
                backgroundImage: booking.student?.avatarUrl != null 
                    ? NetworkImage(booking.student!.avatarUrl!)
                    : null,
                child: booking.student?.avatarUrl == null
                    ? Text(
                        (booking.student?.name.isNotEmpty == true 
                            ? booking.student!.name[0].toUpperCase() 
                            : 'HV'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: EduTheme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.student?.name ?? 'Học viên #${booking.userId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: EduTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('HH:mm').format(booking.date)} - ${DateFormat('dd/MM/yyyy').format(booking.date)}',
                      style: TextStyle(fontSize: 13, color: EduTheme.textSecondary),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(booking.totalPrice),
                      style: const TextStyle(fontSize: 13, color: EduTheme.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EduTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Chi tiết', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    bool trend = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EduTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: EduTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: EduTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: trend ? EduTheme.success : EduTheme.textSecondary,
              fontWeight: trend ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Quick Actions Grid 4x2
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: EduTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard_customize_rounded, size: 18, color: EduTheme.primary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Thao tác nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Group 1: Giảng dạy (Teaching)
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Giảng dạy & Lớp học', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            _buildQuickActionButton(
              context,
              icon: Icons.add_circle_rounded,
              label: 'Tạo lớp',
              gradient: [EduTheme.primary, EduTheme.primaryLight],
              onTap: () => context.push('/create-class'),
            ),
             _buildQuickActionButton(
              context,
              icon: Icons.class_rounded,
              label: 'Lớp học',
              gradient: [Colors.orange, Colors.orangeAccent],
              onTap: () => context.push('/my-classes?index=0'),
            ),
             _buildQuickActionButton(
              context,
              icon: Icons.person_search_rounded,
              label: 'Dạy kèm',
              gradient: [const Color(0xFF10B981), const Color(0xFF34D399)],
              onTap: () => context.push('/my-classes?index=1'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.notifications_active_rounded,
              label: 'Yêu cầu',
              gradient: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
              onTap: () => context.go('/tutor-dashboard/booking-requests'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.chat_bubble_rounded,
              label: 'Chat',
              gradient: [EduTheme.purple, const Color(0xFFC084FC)],
              onTap: () => context.push('/tutor-dashboard/messages'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Group 2: Tuyển sinh & Tài chính (Growth)
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Tuyển sinh & Tài chính', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
             _buildQuickActionButton(
              context,
              icon: Icons.search_rounded,
              label: 'Tìm HV',
              gradient: [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
              onTap: () => context.go('/tutor-dashboard/find-students'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.auto_awesome_rounded,
              label: 'Việc gợi ý',
              gradient: [const Color(0xFF8B5CF6), const Color(0xFFC4B5FD)],
              onTap: () => context.go('/tutor-dashboard/recommended-requests'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.bar_chart_rounded,
              label: 'Thống kê',
              gradient: [Colors.pink, Colors.pinkAccent],
              onTap: () => context.push('/tutor-dashboard/statistics'),
            ),
            _buildQuickActionButton(
              context,
              icon: Icons.account_balance_wallet_rounded,
              label: 'Học phí',
              gradient: [EduTheme.success, const Color(0xFF34D399)],
              onTap: () => context.push('/tutor-dashboard/tuition'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Group 3: Khác (Others)
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Khác', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.article_rounded,
                label: 'Blog',
                gradient: [Colors.indigo, Colors.indigoAccent],
                onTap: () => context.push('/tutor-dashboard/blog'),
              ),
            ),
            const SizedBox(width: 10),
             Expanded(
              child: _buildQuickActionButton(
                context,
                icon: Icons.settings_rounded,
                label: 'Cài đặt',
                gradient: [Colors.blueGrey, Colors.blueGrey.shade300],
                onTap: () => context.push('/settings'),
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(flex: 2), // Fill remaining space for alignment 4-column-like
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Today's Schedule
  Widget _buildTodaySchedule(BuildContext context, AsyncValue classesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: EduTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_note_rounded, size: 18, color: EduTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EduMarquee(
                text: 'Lớp học sắp tới hoặc lớp học hôm nay',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        classesAsync.when(
          skipLoadingOnRefresh: true,
          data: (classes) {
            if (classes.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EduTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.free_breakfast_rounded, size: 40, color: EduTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('Không có lớp học hôm nay', style: TextStyle(color: EduTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            }
            
            // Take first 2 classes for demo
            return Column(
              children: classes.take(2).map<Widget>((cls) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: EduTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getSubjectColor(cls.subject).withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => context.push('/class-detail', extra: cls),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getSubjectColor(cls.subject).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getSubjectIcon(cls.subject), color: _getSubjectColor(cls.subject), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cls.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: EduTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 14, color: EduTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '14:00 - 16:00',
                                          style: TextStyle(color: EduTheme.textSecondary, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Student avatars
                              SizedBox(
                                height: 24,
                                width: (cls.students.length > 3 ? 3 : cls.students.length) * 16.0 + 12.0,
                                child: Stack(
                                  children: List.generate(
                                    (cls.students.length > 3 ? 3 : cls.students.length),
                                    (index) => Positioned(
                                      left: index * 12.0,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: EduTheme.primary.withValues(alpha: 0.2),
                                        child: Text(
                                          (cls.students[index]['name'] ?? 'H')[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 10, color: EduTheme.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${cls.students.length} học viên',
                                style: TextStyle(color: EduTheme.textSecondary, fontSize: 12),
                              ),
                              const Spacer(),
                              // Action Buttons
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        content: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Đang khởi tạo phòng học...'),
                                          ],
                                        ),
                                      ),
                                    );
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        context.push('/video-call', extra: cls.id);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [EduTheme.success, Color(0xFF34D399)]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text('Bắt đầu', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => context.push('/tutor-dashboard/messages'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: EduTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.chat_bubble_rounded, color: EduTheme.primary, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: EduTheme.primary)),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Performance Insights - Simple bar chart
  Widget _buildPerformanceInsights() {
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final earnings = [100, 150, 120, 180, 140, 200, 160]; // Demo data (in k VND)
    final maxEarning = earnings.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: EduTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.trending_up_rounded, size: 18, color: EduTheme.success),
            ),
            const SizedBox(width: 10),
            const Text(
              'Thu nhập 7 ngày qua',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EduTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Simple bar chart
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final height = (earnings[index] / maxEarning) * 100;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 32,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [EduTheme.success, EduTheme.success.withValues(alpha: 0.6)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekDays[index],
                          style: TextStyle(fontSize: 10, color: EduTheme.textSecondary),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EduTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: EduTheme.success, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tổng tuần này: ',
                      style: TextStyle(fontSize: 13, color: EduTheme.textSecondary),
                    ),
                    Text(
                      '1.050.000đ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EduTheme.success),
                    ),
                    Spacer(),
                    Text(
                      '+20%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EduTheme.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Recent Activities
  Widget _buildRecentActivities() {
    final activities = [
      {'icon': Icons.person_add_rounded, 'text': 'Nguyễn A vừa đăng ký lớp Toán 12', 'time': '2 giờ trước', 'color': EduTheme.success},
      {'icon': Icons.star_rounded, 'text': 'Bạn nhận được review 5⭐ từ Trần B', 'time': '5 giờ trước', 'color': Colors.amber},
      {'icon': Icons.notifications_rounded, 'text': 'Học viên mới: Lê C tìm gia sư Hóa', 'time': '1 ngày trước', 'color': EduTheme.secondary},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: EduTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_rounded, size: 18, color: EduTheme.secondary),
            ),
            const SizedBox(width: 10),
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EduTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: activities.map<Widget>((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['text'] as String,
                            style: const TextStyle(fontSize: 13, color: EduTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['time'] as String,
                            style: TextStyle(fontSize: 11, color: EduTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: EduTheme.textSecondary),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Student Requests Preview
  Widget _buildStudentRequestsPreview(BuildContext context, AsyncValue requestsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: EduTheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_rounded, size: 18, color: EduTheme.secondary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Học viên cần tìm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: EduTheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/tutor-dashboard/find-students'),
              child: const Text('Xem tất cả', style: TextStyle(color: EduTheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        requestsAsync.when(
          skipLoadingOnRefresh: true,
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();
            
            final req = requests.first;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EduTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EduTheme.secondary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getSubjectColor(req.subject).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getSubjectIcon(req.subject), color: _getSubjectColor(req.subject), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tìm gia sư ${req.subject}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: EduTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: EduTheme.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    req.gradeLevel,
                                    style: const TextStyle(color: EduTheme.secondary, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(req.minBudget/1000).toInt()}-${(req.maxBudget/1000).toInt()}k/h',
                                  style: const TextStyle(color: EduTheme.success, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.go('/tutor-dashboard/find-students'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [EduTheme.primary, EduTheme.purple]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Xem',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Get icon for subject
  IconData _getSubjectIcon(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('toán')) return Icons.calculate_rounded;
    if (subjectLower.contains('văn')) return Icons.edit_note_rounded;
    if (subjectLower.contains('anh')) return Icons.translate_rounded;
    if (subjectLower.contains('lý')) return Icons.bolt_rounded;
    if (subjectLower.contains('hóa')) return Icons.science_rounded;
    if (subjectLower.contains('sinh')) return Icons.biotech_rounded;
    if (subjectLower.contains('sử')) return Icons.history_edu_rounded;
    if (subjectLower.contains('địa')) return Icons.public_rounded;
    if (subjectLower.contains('tin')) return Icons.computer_rounded;
    return Icons.auto_stories_rounded;
  }

  /// Get color for subject
  Color _getSubjectColor(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('toán')) return const Color(0xFF3B82F6);
    if (subjectLower.contains('văn')) return const Color(0xFFEC4899);
    if (subjectLower.contains('anh')) return const Color(0xFF8B5CF6);
    if (subjectLower.contains('lý')) return const Color(0xFFF59E0B);
    if (subjectLower.contains('hóa')) return const Color(0xFF10B981);
    if (subjectLower.contains('sinh')) return const Color(0xFF14B8A6);
    if (subjectLower.contains('sử')) return const Color(0xFFF97316);
    if (subjectLower.contains('địa')) return const Color(0xFF06B6D4);
    if (subjectLower.contains('tin')) return const Color(0xFF6366F1);
    return EduTheme.primary;
  }
}
