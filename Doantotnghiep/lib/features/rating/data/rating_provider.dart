
import 'package:doantotnghiep/features/rating/domain/models/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RatingNotifier extends Notifier<List<Review>> {
  @override
  List<Review> build() {
    return [];
  }

  // Blind Review Logic
  void submitReview(Review newReview) {
    // 1. Check if the "other party" has already reviewed for this bookingId
    final otherReviewIndex = state.indexWhere((r) => r.bookingId == newReview.bookingId && r.userId != newReview.userId);

    if (otherReviewIndex != -1) {
      // CASE: Match Found! Reveal both.
      final otherReview = state[otherReviewIndex];
      
      // Update other review to Visible
      final updatedOther = otherReview.copyWith(isVisible: true);
      
      // Current review is also Visible immediately
      final updatedCurrent = newReview.copyWith(isVisible: true);

      state = [
        ...state.where((r) => r.id != otherReview.id), // Remove old 'other'
        updatedOther,
        updatedCurrent,
      ];
    } else {
      // CASE: First to review. Keep hidden.
      // In real backend, this would be 'pending_reveal'
      state = [...state, newReview.copyWith(isVisible: false)];
    }
  }

  // Get visible reviews for a Tutor
  List<Review> getTutorReviews(String tutorId) {
    return state.where((r) => r.tutorId == tutorId && r.isVisible).toList();
  }
}

final ratingProvider = NotifierProvider<RatingNotifier, List<Review>>(RatingNotifier.new);
