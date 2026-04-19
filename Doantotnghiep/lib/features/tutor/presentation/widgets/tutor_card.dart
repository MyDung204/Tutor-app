/// Tutor Card Widget
/// 
/// Displays a summary card for a tutor with:
/// - Avatar image
/// - Name and verification badge
/// - Subjects taught
/// - Rating and review count
/// - Hourly rate
/// - Tier badge (Teacher/Student)
/// - Location
/// 
/// **Design:**
/// - Modern glassmorphism effect (backdrop blur)
/// - Rounded corners (20px)
/// - Subtle shadow for depth
/// - Tap to navigate to tutor detail screen
/// 
/// **Usage:**
/// ```dart
/// TutorCard(
///   tutor: tutor,
///   onTap: () => context.push('/tutor-detail', extra: tutor),
/// )
/// ```
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thẻ hiển thị thông tin tóm tắt của một Gia sư
/// 
/// **Hiển thị:**
/// - Avatar, Tên, Giá, Đánh giá, và Nhãn (Giáo viên/Sinh viên)
/// 
/// **Thiết kế:**
/// - Glassmorphism effect (hiệu ứng kính mờ)
/// - Bo góc 20px
/// - Shadow nhẹ
/// - Có thể tap để xem chi tiết
class TutorCard extends StatelessWidget {
  /// Tutor object to display
  final Tutor tutor;
  
  /// Callback when card is tapped
  /// Usually navigates to tutor detail screen
  final VoidCallback? onTap;

  const TutorCard({super.key, required this.tutor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6), // Glass effect base
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tutor.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tutor.isVerified)
                              const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 8),
                            _FavoriteButton(tutor: tutor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tutor.subjects.join(', '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${tutor.rating}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${tutor.reviewCount})',
                              style: const TextStyle(color: Colors.black45, fontSize: 12),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${currencyFormat.format(tutor.hourlyRate)}/h',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                           children: [
                             Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: tutor.tier == 'teacher' ? Colors.blue[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: tutor.tier == 'teacher' ? Colors.blue : Colors.green, width: 0.5),
                              ),
                              child: Text(
                                tutor.tier == 'teacher' ? 'Giáo viên' : 'Sinh viên',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: tutor.tier == 'teacher' ? Colors.blue[800] : Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                           ],
                         ),
                        const SizedBox(height: 4),
                        Text(
                          tutor.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
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

class _FavoriteButton extends ConsumerStatefulWidget {
  final Tutor tutor;
  const _FavoriteButton({required this.tutor});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  late bool isFavorite;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.tutor.isFavorite;
  }

  void _toggleFavorite() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    
    try {
      final newStatus = await ref.read(tutorRepositoryProvider).toggleFavorite(widget.tutor.id);
      if (mounted) {
        setState(() {
          isFavorite = newStatus;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi thực hiện. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleFavorite,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
                size: 24,
              ),
      ),
    );
  }
}
