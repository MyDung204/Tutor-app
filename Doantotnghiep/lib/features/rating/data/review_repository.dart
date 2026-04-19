import 'package:doantotnghiep/features/rating/domain/models/review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return MockReviewRepository();
});

abstract class ReviewRepository {
  Future<List<Review>> getReviewsForTutor(String tutorId);
}

class MockReviewRepository implements ReviewRepository {
  @override
  Future<List<Review>> getReviewsForTutor(String tutorId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay
    return [
      Review(
        id: '1',
        bookingId: 'booking_1',
        tutorId: tutorId,
        userId: 'u1',
        userName: 'Nguyễn Thị Hoa',
        userAvatar: 'https://i.pravatar.cc/150?u=u1',
        rating: 5.0,
        comment: 'Gia sư dạy rất dễ hiểu, bé nhà mình tiến bộ rõ rệt.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Review(
        id: '2',
        bookingId: 'booking_2',
        tutorId: tutorId,
        userId: 'u2',
        userName: 'Trần Minh Quân',
        userAvatar: 'https://i.pravatar.cc/150?u=u2',
        rating: 4.0,
        comment: 'Nhiệt tình nhưng đôi khi đến muộn chút xíu.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Review(
        id: '3',
        bookingId: 'booking_3',
        tutorId: tutorId,
        userId: 'u3',
        userName: 'Lê Văn Tám',
        userAvatar: 'https://i.pravatar.cc/150?u=u3',
        rating: 5.0,
        comment: 'Tuyệt vời, sẽ đặt lịch dài hạn.',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
       Review(
        id: '4',
        bookingId: 'booking_4',
        tutorId: tutorId,
        userId: 'u4',
        userName: 'Phạm Hương',
        userAvatar: 'https://i.pravatar.cc/150?u=u4',
        rating: 3.0,
        comment: 'Dạy ổn, nhưng cần chuẩn bị bài kỹ hơn.',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
       Review(
        id: '5',
        bookingId: 'booking_5',
        tutorId: tutorId,
        userId: 'u5',
        userName: 'Hoàng Long',
        userAvatar: 'https://i.pravatar.cc/150?u=u5',
        rating: 1.0,
        comment: 'Không chuyên nghiệp, hủy lịch sát giờ.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
