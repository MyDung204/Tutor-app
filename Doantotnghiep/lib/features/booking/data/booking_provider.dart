/// Booking Data Layer
/// 
/// Manages booking data and operations:
/// - Fetching user's bookings
/// - Locking time slots (temporary reservation)
/// - Confirming bookings (permanent booking)
/// - Cancelling bookings
/// - Checking slot availability
/// 
/// **Status Flow:**
/// - 'Locked': Temporary reservation (10 minutes)
/// - 'Upcoming': Confirmed booking
/// - 'Cancelled': Cancelled booking
/// - 'Completed': Past booking
library;

import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:doantotnghiep/core/network/api_constants.dart';
import 'package:doantotnghiep/core/exceptions/app_exceptions.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/wallet/data/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Booking Item Model
/// 
/// Represents a single booking session with tutor.
/// Contains all information needed to display and manage a booking.
/// 
/// **Fields:**
/// - `id`: Unique booking ID from server
/// - `userId`: ID of user who made the booking
/// - `tutor`: Tutor object (can be partial/minimal data)
/// - `date`: Booking date
/// - `timeSlot`: Time slot string (e.g., "09:00 - 11:00")
/// - `totalPrice`: Total price for the session
/// - `status`: Booking status ('Locked', 'Upcoming', 'Cancelled', 'Completed')
/// - `lockedUntil`: Expiration time for locked bookings (null if confirmed)
import 'package:doantotnghiep/features/auth/domain/models/app_user.dart';

class BookingItem {
  final String id;
  final String userId;
  final Tutor tutor; 
  final AppUser? student; // Added student field for Tutor View
  final DateTime date;
  final String timeSlot;
  final double totalPrice;
  final String status; 
  final DateTime? lockedUntil;
  final String type; // 'single' | 'long_term'
  final String learningMode; // 'online' | 'offline'
  final String? lessonTopic;
  final String? tutorFeedback;
  final String? meetingLink;
  final String? gradeLevel;

  BookingItem({
    required this.id,
    required this.userId,
    required this.tutor,
    this.student,
    required this.date,
    required this.timeSlot,
    required this.totalPrice,
    this.status = 'Upcoming',
    this.lockedUntil,
    this.type = 'single',
    this.learningMode = 'online',
    this.lessonTopic,
    this.tutorFeedback,
    this.meetingLink,
    this.gradeLevel,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      tutor: Tutor.fromJson(json['tutor']),
      student: json['student'] != null ? AppUser.fromJson(json['student']) : null,
      date: DateTime.parse(json['date'] ?? json['start_time']),
      timeSlot: json['time_slot'] ?? 
                '${DateFormat('HH:mm').format(DateTime.parse(json['start_time']))} - ${DateFormat('HH:mm').format(DateTime.parse(json['end_time']))}',
      totalPrice: double.tryParse((json['total_price'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      status: _mapStatus(json['status'] ?? 'Upcoming'),
      lockedUntil: json['locked_until'] != null ? DateTime.parse(json['locked_until']) : null,
      type: json['type'] ?? 'single',
      learningMode: json['learning_mode'] ?? 'online',
      lessonTopic: json['lesson_topic'],
      tutorFeedback: json['tutor_feedback'],
      meetingLink: json['meeting_link'],
      gradeLevel: json['grade_level'],
    );
  }

  static String _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'locked':
        return 'Locked';
      case 'upcoming':
      case 'confirmed':
        return 'Upcoming';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'completed':
      case 'finished':
        return 'Completed';
      default:
        return 'Upcoming';
    }
  }

  BookingItem copyWith({
    String? status,
    DateTime? lockedUntil,
    String? lessonTopic,
    String? tutorFeedback,
    String? gradeLevel,
  }) {
    return BookingItem(
      id: id,
      userId: userId,
      tutor: tutor,
      student: student,
      date: date,
      timeSlot: timeSlot,
      totalPrice: totalPrice,
      status: status ?? this.status,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      type: type,
      learningMode: learningMode,
      lessonTopic: lessonTopic ?? this.lessonTopic,
      tutorFeedback: tutorFeedback ?? this.tutorFeedback,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      meetingLink: meetingLink,
    );
  }
}

/// Booking Notifier - Manages booking data state
/// 
/// Uses Riverpod AsyncNotifier to manage list of bookings.
/// Provides methods for booking operations (lock, confirm, cancel).
/// 
/// **State:**
/// - `AsyncValue<List<BookingItem>>`: Loading/data/error states
/// - Automatically refetches on invalidate
class BookingNotifier extends AsyncNotifier<List<BookingItem>> {
  /// Initialize booking list from API
  /// 
  /// **Returns:**
  /// - `Future<List<BookingItem>>`: List of user's bookings
  /// 
  /// **API Endpoint:**
  /// - `GET /bookings` (returns bookings for authenticated user)
  /// 
  /// **Error Handling:**
  /// - Returns empty list on error (fails gracefully)
  /// - Logs error for debugging
  @override
  Future<List<BookingItem>> build() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.get(ApiConstants.bookings);
      
      // Parse response
      if (response is List) {
        return response.map((e) => BookingItem.fromJson(e)).toList();
      }
      
      // Return empty list if response format is unexpected
      return [];
    } on ApiException catch (e) {
      // Handle API errors gracefully
      print('API Error (Fetch Bookings): ${e.userMessage}');
      // Don't return empty list on error, rethrow to let UI handle it (and keep old data)
      rethrow;
    } catch (e) {
      // Handle unexpected errors
      print('Unexpected Error (Fetch Bookings): $e');
      rethrow;
    }
  }

  /// Check if a time slot is available (client-side check)
  /// 
  /// **Parameters:**
  /// - `tutorId`: ID of tutor to check
  /// - `date`: Date to check
  /// - `time`: Time slot string
  /// 
  /// **Returns:**
  /// - `bool`: true if available, false if booked or locked
  /// 
  /// **Purpose:**
  /// - Optimistic UI check (disables unavailable slots)
  /// - Server also validates (this is for UX only)
  /// 
  /// **Logic:**
  /// - Checks if any booking exists for same tutor/date/time
  /// - Returns false if status is 'Upcoming' (permanently booked)
  /// - Returns false if status is 'Locked' (temporarily reserved)
  /// 
  /// **NOTE:** This is client-side only. Server validation is authoritative.
  /// Race conditions are handled by server-side checks.
  bool isSlotAvailable(String tutorId, DateTime date, String time) {
    // Get current bookings from state
    // state.value is null during loading, so we default to empty list
    final currentList = state.value ?? [];
    final dateStr = DateFormat('yyyyMMdd').format(date);
    
    // Check if any booking conflicts with requested slot
    return !currentList.any((b) => 
      b.tutor.id == tutorId &&
      DateFormat('yyyyMMdd').format(b.date) == dateStr &&
      b.timeSlot == time &&
      (b.status == 'Upcoming' || b.status == 'Locked') // Only check active bookings
    );
  }

  /// Lock a time slot (temporary reservation)
  /// 
  /// **Parameters:**
  /// - `item`: BookingItem with booking details
  /// 
  /// **Returns:**
  /// - `Future<String>`: Server-generated booking ID
  /// 
  /// **Purpose:**
  /// - Reserves time slot for 10 minutes
  /// - Prevents other users from booking same slot
  /// - Allows time for payment process
  /// 
  /// **Process:**
  /// 1. Sends lock request to server
  /// 2. Server validates availability and creates lock
  /// 3. Returns booking ID
  /// 4. Invalidates provider to refresh booking list
  /// 
  /// **API Endpoint:**
  /// - `POST /bookings/lock`
  /// 
  /// **Throws:**
  /// - `Exception`: If lock fails (slot already taken, etc.)
  /// 
  /// **Example:**
  /// ```dart
  /// final bookingId = await notifier.lockSlot(bookingItem);
  /// // Use bookingId for confirmation
  /// ```
  Future<String> lockSlot(BookingItem item, {
    String? type,
    int? durationMonths,
    List<int>? daysOfWeek,
    String? learningMode,
    bool? payFull,
    String? paymentPin,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      // POST /bookings/lock
      final data = {
        'tutor_id': item.tutor.id,
        'date': item.date.toIso8601String(),
        'time_slot': item.timeSlot,
        'price': item.totalPrice,
        'type': type,
        if (durationMonths != null) 'duration_months': durationMonths,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        if (learningMode != null) 'learning_mode': learningMode,
        if (payFull != null) 'pay_full': payFull,
        if (paymentPin != null) 'payment_pin': paymentPin,
      };

      final response = await apiClient.post('${ApiConstants.bookings}/lock', data: data);
      
      // Refresh booking list to include new lock
      ref.invalidateSelf();
      // Refresh wallet balance
      ref.invalidate(walletProvider);
      
      // Extract booking ID from response
      // Backend returns: { 'id': 123, ... }
      if (response is Map<String, dynamic> && response.containsKey('id')) {
         return response['id'].toString();
      }
      
      // Return empty string if ID not found (should not happen)
      return '';
    } on ApiException catch (e) {
      // Convert API exception to user-friendly message
      if (e.statusCode == 409) {
        throw BookingException.slotAlreadyBooked();
      }
      throw BookingException(
        type: BookingErrorType.unknown,
        userMessage: e.userMessage,
      );
    } catch (e) {
      // Handle unexpected errors
      throw Exception("Không thể giữ chỗ: $e");
    }
  }

  /// Confirm a booking (convert lock to permanent booking)
  /// 
  /// **Parameters:**
  /// - `id`: Booking ID from lockSlot() response
  /// 
  /// **Purpose:**
  /// - Converts temporary lock to confirmed booking
  /// - Called after successful payment
  /// - Status changes from 'Locked' to 'Upcoming'
  /// 
  /// **Process:**
  /// 1. Sends confirm request to server
  /// 2. Server converts lock to confirmed booking
  /// 3. Invalidates provider to refresh booking list
  /// 
  /// **API Endpoint:**
  /// - `POST /bookings/{id}/confirm`
  /// 
  /// **Error Handling:**
  /// - Logs error but doesn't throw (non-critical for UX)
  /// - Booking may already be confirmed or cancelled
  /// 
  /// **Example:**
  /// ```dart
  /// await notifier.confirmBooking(bookingId);
  /// // Booking is now confirmed
  /// ```
  Future<void> confirmBooking(String id) async {
     final apiClient = ref.read(apiClientProvider);
     try {
       // POST /bookings/{id}/confirm
       // Server converts 'Locked' status to 'Upcoming'
       await apiClient.post('${ApiConstants.bookings}/$id/confirm');
       
       // Refresh booking list to show updated status
       ref.invalidateSelf();
     } on ApiException catch (e) {
       // Log error but don't throw (non-critical)
       // Booking may already be confirmed or cancelled
       print('Confirm Error: ${e.userMessage}');
     } catch (e) {
       print('Unexpected Confirm Error: $e');
     }
  }

  /// Cancel a booking
  /// 
  /// **Parameters:**
  /// - `id`: Booking ID to cancel
  /// 
  /// **Purpose:**
  /// - Cancels a confirmed or locked booking
  /// - Server handles refund logic based on cancellation policy
  /// 
  /// **Process:**
  /// 1. Sends cancel request to server
  /// 2. Server updates status to 'Cancelled'
  /// 3. Server processes refund (if applicable)
  /// 4. Invalidates provider to refresh booking list
  /// 
  /// **API Endpoint:**
  /// - `POST /bookings/{id}/cancel`
  /// 
  /// **Refund Policy:**
  /// - Cancelled > 24h before: Full refund
  /// - Cancelled < 24h before: Partial/no refund (handled by server)
  /// 
  /// **Error Handling:**
  /// - Logs error but doesn't throw (non-critical for UX)
  /// 
  /// **Example:**
  /// ```dart
  /// await notifier.cancelBooking(bookingId);
  /// // Booking is cancelled, refund processed
  /// ```
  Future<void> cancelBooking(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      // POST /bookings/{id}/cancel
      // Server handles refund logic based on cancellation policy
      // Refund amount depends on time until booking start
      await apiClient.post('${ApiConstants.bookings}/$id/cancel');
      
      // Refresh booking list to show cancelled status
      ref.invalidateSelf();
      ref.invalidate(walletProvider); // Refund update
    } on ApiException catch (e) {
      // Log error for debugging
      print('Cancel Error: ${e.userMessage}');
    } catch (e) {
      print('Unexpected Cancel Error: $e');
    }
  }

  /// Reject a booking request (Tutor side)
  Future<void> rejectBooking(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('${ApiConstants.bookings}/$id/reject');
      ref.invalidateSelf();
    } on ApiException catch (e) {
      print('Reject Error: ${e.userMessage}');
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Update Session Info (Lesson Topic, Feedback)
  Future<void> updateSessionInfo(String id, {String? lessonTopic, String? tutorFeedback, bool? completed, String? meetingLink}) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final data = {
        if (lessonTopic != null) 'lesson_topic': lessonTopic,
        if (tutorFeedback != null) 'tutor_feedback': tutorFeedback,
        if (completed == true) 'status': 'completed',
        if (meetingLink != null) 'meeting_link': meetingLink,
      };
      
      await apiClient.post('${ApiConstants.bookings}/$id/session-info', data: data);
      ref.invalidateSelf();
    } on ApiException catch (e) {
      print('Update Session Info Error: ${e.userMessage}');
      rethrow; 
    } catch (e) {
      print('Unexpected Update Session Error: $e');
      rethrow;
    }
  }
}

/// Provider for BookingNotifier
/// 
/// Creates BookingNotifier instance for managing booking data.
/// Uses AsyncNotifierProvider for async state management.
final bookingProvider = AsyncNotifierProvider<BookingNotifier, List<BookingItem>>(BookingNotifier.new);
