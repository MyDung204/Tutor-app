import 'package:cached_network_image/cached_network_image.dart';
import 'package:doantotnghiep/core/theme/edu_theme.dart';
import 'package:doantotnghiep/features/group/data/group_request_provider.dart';
import 'package:doantotnghiep/features/group/domain/models/group_request.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor/presentation/widgets/tutor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';
import 'package:doantotnghiep/features/student/presentation/my_enrolled_classes_screen.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/notification/presentation/providers/notification_provider.dart';
import 'package:doantotnghiep/features/home/presentation/widgets/scaffold_with_navbar.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';

final featuredTutorsProvider = FutureProvider<List<Tutor>>((ref) {
  return ref.watch(tutorRepositoryProvider).getFeaturedTutors();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Note: Push Up notification on launch removed as per request.
    // Unread messages are now shown in Notification Bell list and Tab Badge.

    final isBottomNavVisible = ref.watch(bottomNavVisibilityProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for better contrast
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: EdgeInsets.only(bottom: isBottomNavVisible ? 100 : 20),
        child: FloatingActionButton(
          onPressed: () => context.push('/map'),
          child: const Icon(Icons.map_outlined),
          tooltip: 'Bản đồ',
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const _HomeHeader(),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const _LearningProgressDashboard(),
                   const SizedBox(height: 20),
                   const _BannerSection(),
                   const SizedBox(height: 20),
                   
                   // Quick Actions Grid
                   const _QuickActionsSection(),
                   const SizedBox(height: 20),
                   
                   // Upcoming Schedule
                   const _UpcomingScheduleSection(),
                   const SizedBox(height: 20),
                   
                   const _CategorySection(),
                   const SizedBox(height: 20),
                   
                   const _FeaturedTutorSection(),
                   const SizedBox(height: 20),
                   
                   const _MyRequestsSection(),
                   const SizedBox(height: 20),

                   const _MyGroupsSection(),
                   const SizedBox(height: 20),

                   const _MyClassesSection(),
                   const SizedBox(height: 20),
                   
                   // Study Tips
                   const _StudyTipsSection(),
                   const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningProgressDashboard extends ConsumerWidget {
  const _LearningProgressDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ideally this data comes from a provider. We use mock/placeholder data for now.
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.value;
    final isTutor = user?.role == 'tutor';

    if (isTutor || user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến độ học tập',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.trending_up, color: Colors.white.withOpacity(0.8)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Tổng số buổi', '24', Icons.calendar_today),
                _hasDivider(),
                _buildStatItem(context, 'Điểm TB', '8.5', Icons.star_border),
                _hasDivider(),
                _buildStatItem(context, 'Chuyên cần', '95%', Icons.check_circle_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hasDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }
}


class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final user = userAsync.value;
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      backgroundColor: EduTheme.primary,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      floating: false, 
      expandedHeight: 180, 
      toolbarHeight: 0, // Collapsed height set to 0. Pinned bottom widget remains.
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [EduTheme.primary, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          // Dynamic padding based on safe area
          padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 60), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty 
                      ? NetworkImage(user.avatarUrl!) 
                      : null,
                  child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty) 
                      ? const Icon(Icons.person, color: Colors.grey, size: 28) 
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Xin chào,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      user?.name ?? 'Bạn học',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
                    final count = unreadCountAsync.value ?? 0;

                    return IconButton(
                      icon: Badge(
                         isLabelVisible: count > 0,
                         smallSize: 10, // Small red dot as requested
                         backgroundColor: Colors.red,
                         child: const Icon(Icons.notifications_outlined, color: Colors.white), 
                      ),
                      onPressed: () => context.push('/notifications')
                    );
                  }
                ),
              )
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          height: 70,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => context.go('/search'),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                   Icon(Icons.search_rounded, color: EduTheme.primary),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text('Tìm giáo viên, môn học...', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerSection extends StatefulWidget {
  const _BannerSection();

  @override
  State<_BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<_BannerSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Tìm Gia Sư\nChất Lượng Cao',
      'subtitle': 'Đội ngũ giảng viên uy tín\ntừ các trường đại học hàng đầu',
      'image': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
      'action': '/search',
      'buttonText': 'Khám phá ngay',
    },
    {
      'title': 'Học nhóm\nHiệu quả hơn',
      'subtitle': 'Tham gia nhóm học tập\nvới bạn bè cùng môn',
      'image': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
      'action': '/my-study-groups',
      'buttonText': 'Tham gia ngay',
    },
    {
      'title': 'Đăng ký\nLớp học mới',
      'subtitle': 'Khám phá các lớp học\nphù hợp với bạn',
      'image': 'https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
      'action': '/search?tab=classes',
      'buttonText': 'Xem lớp học',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push(banner['action'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: banner['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (banner['gradient'] as List<Color>)[0].withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned(
                          right: -30,
                          bottom: -30,
                          child: Icon(
                            Icons.school_rounded,
                            size: 150,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banner['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  banner['buttonText'] as String,
                                  style: TextStyle(
                                    color: (banner['gradient'] as List<Color>)[0],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? EduTheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Toán', 'icon': Icons.calculate_outlined, 'color': Colors.blue},
      {'label': 'Tiếng Anh', 'icon': Icons.language, 'color': Colors.orange},
      {'label': 'Vật lý', 'icon': Icons.flash_on_outlined, 'color': Colors.purple},
      {'label': 'Hóa học', 'icon': Icons.science_outlined, 'color': Colors.green},
      {'label': 'Văn học', 'icon': Icons.book_outlined, 'color': Colors.red},
      {'label': 'Piano', 'icon': Icons.music_note_outlined, 'color': Colors.pink},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Khám phá môn học', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                margin: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  avatar: Icon(cat['icon'] as IconData, size: 18, color: (cat['color'] as MaterialColor).shade700),
                  label: Text(cat['label'] as String, style: TextStyle(color: (cat['color'] as MaterialColor).shade900, fontWeight: FontWeight.w600, fontSize: 13)),
                  backgroundColor: (cat['color'] as Color).withOpacity(0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  onPressed: () {
                     context.go(Uri(path: '/search', queryParameters: {'subject': cat['label'] as String}).toString());
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedTutorSection extends ConsumerWidget {
  const _FeaturedTutorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorsAsyncValue = ref.watch(featuredTutorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gia sư nổi bật', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => context.go('/search'),
                child: Text('Xem tất cả', style: TextStyle(color: EduTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // Slightly increased height
          child: tutorsAsyncValue.when(
            data: (tutors) {
              if (tutors.isEmpty) {
                 return const Center(child: Text('Không có gia sư nổi bật', style: TextStyle(color: Colors.grey)));
              }
              final displayTutors = tutors;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayTutors.length,
                itemBuilder: (context, index) {
                   final tutor = displayTutors[index];
                   return Container(
                     width: 180,
                     margin: const EdgeInsets.only(right: 12, bottom: 10), // Added bottom margin for shadow
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                       border: Border.all(color: Colors.grey.shade50)
                     ),
                     child: InkWell(
                        onTap: () => context.push('/tutor-detail', extra: tutor),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: CachedNetworkImage(
                                    imageUrl: tutor.avatarUrl.isNotEmpty ? tutor.avatarUrl : 'https://via.placeholder.com/150',
                                    height: 110,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.person)),
                                  ),
                                ),
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 10),
                                        const SizedBox(width: 2),
                                        Text('${tutor.rating}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                if (tutor.tier == 'teacher')
                                  Positioned(
                                    top: 8, left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Giáo viên', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tutor.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(tutor.subjects.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ/h').format(tutor.hourlyRate)}',
                                    style: TextStyle(color: EduTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                     ),
                   );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (_, __) => Container(
                width: 180, margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
              )
            ),
            error: (err, stack) => Center(child: Text('Lỗi: $err')),
          ),
        ),
      ],
    );
  }
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3436), // Dark trendy color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
             child: const Icon(Icons.forum_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cộng đồng Hỏi Đáp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('Tham gia thảo luận & giải bài tập', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/community'),
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
          )
        ],
      ),
    );
  }
}

class _MyRequestsSection extends ConsumerWidget {
  const _MyRequestsSection();

  IconData _getSubjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('toán')) return Icons.calculate_rounded;
    if (s.contains('anh') || s.contains('english')) return Icons.language_rounded;
    if (s.contains('lý')) return Icons.bolt_rounded;
    if (s.contains('hóa')) return Icons.science_rounded;
    if (s.contains('sinh')) return Icons.biotech_rounded;
    if (s.contains('văn')) return Icons.menu_book_rounded;
    if (s.contains('sử')) return Icons.history_edu_rounded;
    if (s.contains('địa')) return Icons.public_rounded;
    if (s.contains('tin')) return Icons.computer_rounded;
    if (s.contains('nhạc') || s.contains('piano')) return Icons.music_note_rounded;
    return Icons.school_rounded;
  }

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('toán')) return Colors.blue;
    if (s.contains('anh') || s.contains('english')) return Colors.orange;
    if (s.contains('lý')) return Colors.purple;
    if (s.contains('hóa')) return Colors.green;
    if (s.contains('sinh')) return Colors.teal;
    if (s.contains('văn')) return Colors.pink;
    if (s.contains('sử')) return Colors.brown;
    if (s.contains('địa')) return Colors.cyan;
    if (s.contains('tin')) return Colors.indigo;
    if (s.contains('nhạc') || s.contains('piano')) return Colors.red;
    return EduTheme.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRequestsAsync = ref.watch(myTutorRequestsProvider);

    return myRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yêu cầu của tôi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => context.push('/my-requests'),
                    child: Text('Xem tất cả', style: TextStyle(color: EduTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final color = _getSubjectColor(req.subject);
                  final icon = _getSubjectIcon(req.subject);
                  
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/my-request-detail', extra: req),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.subject,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          req.gradeLevel,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: req.status == 'open' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      req.status == 'open' ? 'Đang tìm' : 'Hoàn thành',
                                      style: TextStyle(
                                        color: req.status == 'open' ? Colors.blue : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(req.minBudget),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MyClassesSection extends ConsumerWidget {
  const _MyClassesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(myEnrolledCoursesProvider);

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Lớp học của tôi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   GestureDetector(
                     onTap: () => context.push('/my-enrolled-classes'),
                     child: Text('Xem tất cả', style: TextStyle(color: EduTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                     child: InkWell(
                      onTap: () => context.push('/class-detail', extra: course),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.class_, color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.subject, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(course.schedule, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1),
                                  Text(course.status == 'open' ? 'Đang học' : 'Kết thúc', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: course.status == 'open' ? Colors.green : Colors.grey, fontSize: 11)),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MyGroupsSection extends ConsumerWidget {
  const _MyGroupsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final myGroupsAsync = ref.watch(myGroupsProvider);

    return myGroupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Nhóm học tập', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   GestureDetector(
                     onTap: () => context.push('/my-study-groups'),
                     child: Text('Xem tất cả', style: TextStyle(color: EduTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140, // Height for group card
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final grp = groups[index];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                     child: InkWell(
                      onTap: () => context.push('/group-detail', extra: grp), // Updated route
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Badge(
                                isLabelVisible: grp.pendingRequestsCount > 0 || grp.hasNewMessages,
                                label: grp.pendingRequestsCount > 0 ? Text('${grp.pendingRequestsCount}') : null,
                                smallSize: 10,
                                backgroundColor: Colors.red,
                                offset: const Offset(4, -4),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.groups, color: Colors.blue, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(grp.topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${grp.subject} - ${grp.gradeLevel}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${grp.currentMembers}/${grp.maxMembers} TV', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(grp.pricePerSession), 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: EduTheme.primary, fontSize: 13)),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ============ NEW WIDGETS ============

/// Quick Actions Grid - 4 buttons for common actions
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.person_search_rounded, 'label': 'Tìm gia sư', 'route': '/search', 'color': Colors.blue},
      {'icon': Icons.post_add_rounded, 'label': 'Đăng yêu cầu', 'route': '/create-tutor-request', 'color': Colors.orange},
      {'icon': Icons.group_add_rounded, 'label': 'Tạo nhóm', 'route': '/create-group', 'color': Colors.green},
      {'icon': Icons.calendar_month_rounded, 'label': 'Lịch học', 'route': '/schedule', 'color': Colors.purple},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((action) {
          return Expanded(
            child: GestureDetector(
              onTap: () => context.push(action['route'] as String),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (action['color'] as Color).withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Upcoming Schedule - Shows next class/session
class _UpcomingScheduleSection extends ConsumerWidget {
  const _UpcomingScheduleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final now = DateTime.now();
        BookingItem? imminentBooking;
        int minDiff = 9999;

        for (final b in bookings) {
          if (b.status == 'Upcoming') {
            try {
              final startStr = b.timeSlot.split(' - ')[0]; // "09:00"
              final parts = startStr.split(':');
              final startTime = DateTime(b.date.year, b.date.month, b.date.day, int.parse(parts[0]), int.parse(parts[1]));
              
              final diff = startTime.difference(now).inMinutes;
              // Class is soon (< 30m) or ongoing (> -60m)
              if (diff >= -60 && diff <= 30) {
                if (diff < minDiff) { // pick the closest one
                   minDiff = diff;
                   imminentBooking = b;
                }
              }
            } catch (e) {
              // ignore parse error
            }
          }
        }

        if (imminentBooking != null) {
          return _buildWarningBanner(context, imminentBooking, minDiff);
        }
        return _buildDefaultBanner(context);
      },
      loading: () => _buildDefaultBanner(context),
      error: (_, __) => _buildDefaultBanner(context),
    );
  }

  Widget _buildWarningBanner(BuildContext context, BookingItem booking, int diffMinutes) {
    String statusText = diffMinutes <= 0 ? 'Đang diễn ra' : 'Sắp bắt đầu ($diffMinutes phút)';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/schedule'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.alarm, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lớp học: $statusText',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gia sư: ${booking.tutor.name}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Bấm vào để vào lớp ngay!!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/schedule'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch học sắp tới',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Xem lịch học và buổi học đã đặt',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.indigo.shade600, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Study Tips - Rotating tips for students
class _StudyTipsSection extends StatelessWidget {
  const _StudyTipsSection();

  @override
  Widget build(BuildContext context) {
    final tips = [
      {'icon': Icons.lightbulb_outline, 'tip': 'Chia nhỏ thời gian học thành các phiên 25 phút (Pomodoro)', 'color': Colors.amber},
      {'icon': Icons.psychology_outlined, 'tip': 'Ôn lại bài học trong vòng 24h để nhớ lâu hơn', 'color': Colors.purple},
      {'icon': Icons.edit_note_rounded, 'tip': 'Ghi chép lại những điểm quan trọng bằng từ của bạn', 'color': Colors.teal},
    ];
    
    // Get tip based on day
    final tipIndex = DateTime.now().day % tips.length;
    final tip = tips[tipIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (tip['color'] as Color).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: (tip['color'] as Color).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (tip['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: tip['color'] as Color),
                      const SizedBox(width: 4),
                      Text(
                        'Mẹo học tập hôm nay',
                        style: TextStyle(
                          color: tip['color'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tip['tip'] as String,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
