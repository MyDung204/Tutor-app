/// Student Request List Screen - Redesigned
/// 
/// **Purpose:**
/// - Hiển thị danh sách yêu cầu tìm gia sư từ học viên
/// - Cho phép gia sư tìm kiếm và liên hệ với học viên
/// 
/// **Features:**
/// - Filter theo môn học và trình độ
/// - Modern card design với subject icons
/// - Quick contact với học viên
library;

import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor_dashboard/data/tutor_request_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Education Theme Colors (shared)
class _EduTheme {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color background = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color purple = Color(0xFF7C3AED);
}

class StudentRequestListScreen extends ConsumerStatefulWidget {
  const StudentRequestListScreen({super.key});

  @override
  ConsumerState<StudentRequestListScreen> createState() => _StudentRequestListScreenState();
}

class _StudentRequestListScreenState extends ConsumerState<StudentRequestListScreen> {
  String? _selectedSubject;
  String? _selectedGrade;

  final List<String> _subjects = ['Toán', 'Lý', 'Hóa', 'Văn', 'Anh', 'Sinh', 'Sử', 'Địa', 'Tin', 'Piano', 'Khác'];
  final List<String> _grades = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', 'ĐH'];

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(tutorRequestsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: _EduTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(context),
            
            // Filter Section
            _buildFilterSection(),
            
            // Request List
            Expanded(
              child: requestsAsync.when(
                data: (requests) {
                  final filtered = requests.where((req) {
                    if (_selectedSubject != null && req.subject != _selectedSubject) return false;
                    if (_selectedGrade != null && !req.gradeLevel.contains(_selectedGrade!)) return false;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final req = filtered[index];
                      return _buildRequestCard(context, req, currencyFormat);
                    },
                  );
                },
                error: (err, stack) => Center(child: Text('Lỗi: $err')),
                loading: () => const Center(child: CircularProgressIndicator(color: _EduTheme.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with search hint
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _EduTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _EduTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tìm Học Viên',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _EduTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tìm học viên phù hợp với bạn',
                  style: TextStyle(
                    fontSize: 13,
                    color: _EduTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _EduTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_rounded, color: _EduTheme.primary),
          ),
        ],
      ),
    );
  }

  /// Filter chips section
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: _EduTheme.cardBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              icon: Icons.book_rounded,
              label: _selectedSubject ?? 'Môn học',
              isSelected: _selectedSubject != null,
              onTap: () => _showFilterSheet(context, 'Chọn Môn học', _subjects, (val) {
                setState(() => _selectedSubject = val);
              }),
              onClear: _selectedSubject != null ? () => setState(() => _selectedSubject = null) : null,
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              icon: Icons.school_rounded,
              label: _selectedGrade != null ? 'Lớp $_selectedGrade' : 'Trình độ',
              isSelected: _selectedGrade != null,
              onTap: () => _showFilterSheet(context, 'Chọn Trình độ', _grades, (val) {
                setState(() => _selectedGrade = val);
              }),
              onClear: _selectedGrade != null ? () => setState(() => _selectedGrade = null) : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Modern filter chip
  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _EduTheme.primary : _EduTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _EduTheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : _EduTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _EduTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.white70),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isSelected ? Colors.white70 : _EduTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  /// Request card with modern design
  Widget _buildRequestCard(BuildContext context, dynamic req, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _EduTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with subject and price
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Subject Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getSubjectColor(req.subject).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getSubjectIcon(req.subject),
                        color: _getSubjectColor(req.subject),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Subject & Grade
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tìm gia sư ${req.subject}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: _EduTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _EduTheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  req.gradeLevel,
                                  style: const TextStyle(
                                    color: _EduTheme.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time_rounded, size: 14, color: _EduTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '2 giờ trước',
                                style: TextStyle(color: _EduTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Price Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _EduTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(req.minBudget/1000).toInt()}-${(req.maxBudget/1000).toInt()}k/h',
                        style: const TextStyle(
                          color: _EduTheme.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Description
                if (req.description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    req.description,
                    style: TextStyle(
                      color: _EduTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Location & Schedule
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: _EduTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      req.location.isNotEmpty ? req.location : 'Online',
                      style: TextStyle(color: _EduTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_outlined, size: 14, color: _EduTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req.schedule.isNotEmpty ? req.schedule : 'Linh hoạt',
                        style: TextStyle(color: _EduTheme.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom action
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Student Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _EduTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    req.studentName.isNotEmpty ? req.studentName[0].toUpperCase() : 'H',
                    style: const TextStyle(color: _EduTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    req.studentName.isNotEmpty ? req.studentName : 'Học viên',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
                
                // Contact Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _contactStudent(context, req),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_EduTheme.primary, _EduTheme.purple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _EduTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Liên hệ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _EduTheme.textSecondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 48, color: _EduTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không tìm thấy yêu cầu nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _EduTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc để tìm kiếm',
            style: TextStyle(color: _EduTheme.textSecondary),
          ),
          if (_selectedSubject != null || _selectedGrade != null) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedSubject = null;
                _selectedGrade = null;
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Xóa bộ lọc'),
              style: TextButton.styleFrom(foregroundColor: _EduTheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  /// Contact student action
  void _contactStudent(BuildContext context, dynamic req) {
    final studentAsTarget = Tutor(
      id: req.studentId,
      name: req.studentName,
      bio: 'Học viên',
      hourlyRate: 0,
      subjects: [],
      rating: 0,
      avatarUrl: 'https://i.pravatar.cc/150?u=${req.studentId}',
      reviewCount: 0,
      location: req.location,
      gender: 'Khác',
      teachingMode: [],
      address: '',
      weeklySchedule: {},
      userId: req.studentId, // Critical: Ensure Chat targets Student User ID
    );

    context.push('/chat', extra: {
      'tutor': studentAsTarget,
      'request': req,
    });
  }

  /// Show filter bottom sheet
  void _showFilterSheet(BuildContext context, String title, List<String> items, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((item) => GestureDetector(
                onTap: () {
                  onSelect(item);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _EduTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _EduTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
    if (subjectLower.contains('piano')) return Icons.piano_rounded;
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
    if (subjectLower.contains('piano')) return const Color(0xFFD946EF);
    return _EduTheme.primary;
  }
}
