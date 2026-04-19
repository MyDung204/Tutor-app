import 'package:doantotnghiep/features/rating/data/review_repository.dart';
import 'package:doantotnghiep/features/rating/domain/models/review.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TutorReviewsScreen extends ConsumerStatefulWidget {
  final Tutor tutor;

  const TutorReviewsScreen({super.key, required this.tutor});

  @override
  ConsumerState<TutorReviewsScreen> createState() => _TutorReviewsScreenState();
}

class _TutorReviewsScreenState extends ConsumerState<TutorReviewsScreen> {
  int _selectedFilter = 0; // 0 = All, 5 = 5 stars, etc.

  @override
  Widget build(BuildContext context) {
    // Watch repository to get reviews (Mock Future)
    // For simplicity, we just call the repo directly via ref outside of a FutureProvider for now,
    // or better usage: fetch in initState or use FutureBuilder since it's mock.
    // Let's use FutureBuilder for simplicity in this specific screen.
    
    final reviewRepo = ref.read(reviewRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá & Nhận xét'),
      ),
      body: Column(
        children: [
          // Header / Summary ??? (Maybe later)
          
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(0, 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip(5, '5 Sao'),
                const SizedBox(width: 8),
                _buildFilterChip(4, '4 Sao'),
                const SizedBox(width: 8),
                _buildFilterChip(3, '3 Sao'),
                const SizedBox(width: 8),
                _buildFilterChip(2, '2 Sao'),
                const SizedBox(width: 8),
                _buildFilterChip(1, '1 Sao'),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: FutureBuilder<List<Review>>(
              future: reviewRepo.getReviewsForTutor(widget.tutor.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Lỗi tải đánh giá'));
                }
                
                final allReviews = snapshot.data ?? [];
                
                // Filter Logic
                final displayedReviews = _selectedFilter == 0 
                  ? allReviews 
                  : allReviews.where((r) => r.rating.round() == _selectedFilter).toList();

                if (displayedReviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_border, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có đánh giá ${_selectedFilter > 0 ? '$_selectedFilter sao' : ''} nào',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayedReviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final review = displayedReviews[index];
                    return _buildReviewCard(review);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int stars, String label) {
    final isSelected = _selectedFilter == stars;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? stars : 0; // If uncheck, go back to All? Or just force select.
          // Let's allow force select, if click same, do nothing or toggle? 
          // Use standard ChoiceChip behavior: if already selected, cannot unselect to nothing for radio-like?
          // But here we want custom: click '5 stars' -> filters. Click '5 stars' again -> Maybe nothing or unfilter?
          // Let's just set it. 
          _selectedFilter = stars;
        });
      },
      selectedColor: Colors.amber.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.amber[900] : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: stars > 0 ? const Icon(Icons.star, size: 16, color: Colors.amber) : null,
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                     Text(
                      DateFormat('dd/MM/yyyy').format(review.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              RatingBarIndicator(
                rating: review.rating,
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 16.0,
                direction: Axis.horizontal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment),
        ],
      ),
    );
  }
}
