import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';

/// Summary of booking information for review screen
class BookingSummary {
  final Tutor tutor;
  final DateTime date;
  final String timeSlot;
  final double totalPrice;
  final int durationHours;
  final String? notes;

  BookingSummary({
    required this.tutor,
    required this.date,
    required this.timeSlot,
    required this.totalPrice,
    this.durationHours = 2,
    this.notes,
  });

  /// Calculate price breakdown
  Map<String, double> get priceBreakdown {
    return {
      'Giá mỗi giờ': tutor.hourlyRate,
      'Số giờ': durationHours.toDouble(),
      'Tổng cộng': totalPrice,
    };
  }
}






