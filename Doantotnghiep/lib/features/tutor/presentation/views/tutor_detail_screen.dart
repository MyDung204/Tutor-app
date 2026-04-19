/// Tutor Detail Screen
/// 
/// **Purpose:**
/// - Displays comprehensive information about a tutor
/// - Shows tutor profile, bio, subjects, ratings, and reviews
/// - Provides actions: Chat and Book session
/// 
/// **Features:**
/// - Large avatar with name and location
/// - Statistics (Rating, Reviews, Hourly Rate)
/// - Bio section
/// - Subjects taught (as chips)
/// - Action buttons (Chat, Book)
/// 
/// **Navigation:**
/// - "Nhắn tin" → Opens chat screen with tutor
/// - "Đặt lịch ngay" → Opens booking screen
/// - Reviews count → Opens reviews screen
/// 
/// **Design:**
/// - Clean, scrollable layout
/// - Prominent action buttons at bottom
/// - Modern card-based design
library;

import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Screen displaying detailed information about a tutor
/// 
/// **Parameters:**
/// - `tutor`: Tutor object to display (passed via route extra)
/// 
/// **Layout:**
/// - AppBar with tutor name
/// - Scrollable body with profile info
/// - Fixed bottom action buttons
class TutorDetailScreen extends ConsumerWidget {
  /// Tutor object containing all tutor information
  final Tutor tutor;

  const TutorDetailScreen({super.key, required this.tutor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Premium Sliver App Bar
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).primaryColor,
                leading: IconButton(
                  icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white)),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).primaryColor, Colors.indigo.shade900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Pattern overlay (optional)
                      Opacity(
                        opacity: 0.1,
                        child: Image.network(
                          "https://www.transparenttextures.com/patterns/cubes.png",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      // Avatar & Info
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Hero(
                              tag: 'tutor_avatar_${tutor.id}',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(tutor.avatarUrl),
                                  onBackgroundImageError: (_, __) => const Icon(Icons.person),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tutor.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (tutor.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                                ],
                              ],
                            ),
                            Text(
                              tutor.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      if (tutor.badges.isNotEmpty) ...[
                        Center(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: tutor.badges.map((badge) {
                              final color = badge.colorHex != null 
                                  ? Color(int.parse(badge.colorHex!.replaceAll('#', '0xFF'))) 
                                  : Colors.blue;
                              return Chip(
                                avatar: badge.iconUrl != null 
                                    ? Image.network(badge.iconUrl!, width: 16) 
                                    : null,
                                label: Text(badge.name),
                                backgroundColor: color.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                                ),
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Stats Grid
                      Row(
                        children: [
                          _buildStatCard(
                            context, 
                            "${tutor.rating}", 
                            "Rating", 
                            Icons.star_rounded, 
                            Colors.amber
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/tutor-reviews', extra: tutor),
                              child: _buildStatCard(
                                context, 
                                "${tutor.reviewCount}", 
                                "Reviews", 
                                Icons.comment_rounded, 
                                Colors.blue
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context, 
                            currencyFormat.format(tutor.hourlyRate), 
                            "giờ", 
                            Icons.attach_money_rounded, 
                            Colors.green,
                            isPrice: true
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Education Section (Highlighted)
                      if (tutor.university.isNotEmpty || tutor.degree.isNotEmpty || tutor.phone.isNotEmpty) ...[
                        _buildSectionTitle(context, "Hồ Sơ"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Column(
                            children: [
                              if (tutor.university.isNotEmpty)
                                _buildDetailRow(Icons.school, "Trường", tutor.university, Colors.orange),
                              if (tutor.degree.isNotEmpty) ...[
                                const Divider(height: 24),
                                _buildDetailRow(Icons.workspace_premium, "Bằng cấp", tutor.degree, Colors.purple),
                              ],
                              if (tutor.phone.isNotEmpty) ...[
                                const Divider(height: 24),
                                _buildDetailRow(Icons.phone_android, "SĐT", tutor.phone, Colors.teal),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Bio
                      _buildSectionTitle(context, "Giới thiệu"),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
                        ),
                        child: Text(
                          tutor.bio,
                          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subjects (Chips)
                      _buildSectionTitle(context, "Môn dạy"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: tutor.subjects.map((sub) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Colors.indigo.shade400]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Text(sub, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Schedule
                      _buildSectionTitle(context, "Lịch giảng dạy"),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
                        ),
                        child: _buildScheduleSection(context),
                      ),
                      const SizedBox(height: 100), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Action Bar
          Positioned(
            left: 20, right: 20, bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.push('/chat', extra: tutor),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Nhắn tin"),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/booking', extra: tutor),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Đặt lịch ngay"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color, {bool isPrice = false}) {
    return Expanded(
      flex: isPrice ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isPrice ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        )
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    if (tutor.weeklySchedule.isEmpty) {
      return const Center(child: Text("Chưa có lịch cập nhật"));
    }
    // Sort logic remains same...
    final sortedKeys = tutor.weeklySchedule.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    
    return Column(
      children: sortedKeys.map((day) {
        final slots = tutor.weeklySchedule[day] ?? [];
        if (slots.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8)
                ),
                alignment: Alignment.center,
                child: Text(_getDayName(day), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: slots.map((slot) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(slot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(String key) {
    const map = {'2': 'Thứ 2', '3': 'Thứ 3', '4': 'Thứ 4', '5': 'Thứ 5', '6': 'Thứ 6', '7': 'Thứ 7', '8': 'CN'};
    return map[key] ?? 'Thứ $key';
  }
}
