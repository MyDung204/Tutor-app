import 'dart:async';
import 'package:doantotnghiep/core/exceptions/app_exceptions.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';
import 'package:doantotnghiep/features/booking/domain/models/booking_state.dart';
import 'package:doantotnghiep/features/chat/data/chat_provider.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Time slot status enum for UI display
enum TimeSlotStatus {
  available,
  booked,
  lockedByOthers,
  myLock,
}

/// Admin Provider for BookingViewModel (Family Provider)
final bookingViewModelProvider =
    AsyncNotifierProvider.autoDispose.family<BookingViewModel, BookingState, Tutor>(
  BookingViewModel.new,
);

class BookingViewModel extends AutoDisposeFamilyAsyncNotifier<BookingState, Tutor> {
  late final Tutor _tutor;

  @override
  FutureOr<BookingState> build(Tutor arg) {
    _tutor = arg;
    return BookingState.initial(tutor: _tutor);
  }

  Tutor get tutor => _tutor;

  void selectDate(DateTime date) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(
      selectedDate: date,
      selectedTimeSlot: null,
    ));
  }

  void selectTimeSlot(String? timeSlot) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(selectedTimeSlot: timeSlot));
  }

  void setBookingType(String type) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(bookingType: type));
  }

  void setDuration(int months) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(durationMonths: months));
  }

  void setLearningMode(String mode) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(learningMode: mode));
  }
  
  void toggleDaySelection(int day) {
    if (state.value == null) return;
    final currentDays = List<int>.from(state.value!.selectedDays);
    if (currentDays.contains(day)) {
      currentDays.remove(day);
    } else {
      currentDays.add(day);
    }
    state = AsyncData(state.value!.copyWith(selectedDays: currentDays));
  }

  void updateLongTermSchedule(int day, String slot, bool isSelected) {
     if (state.value == null) return;
     final currentSchedule = Map<int, List<String>>.from(state.value!.longTermSchedule);
     
     if (!currentSchedule.containsKey(day)) {
       currentSchedule[day] = [];
     }
     
     if (isSelected) {
       if (!currentSchedule[day]!.contains(slot)) {
         currentSchedule[day]!.add(slot);
       }
     } else {
       currentSchedule[day]!.remove(slot);
       if (currentSchedule[day]!.isEmpty) {
         currentSchedule.remove(day);
       }
     }
     state = AsyncData(state.value!.copyWith(longTermSchedule: currentSchedule));
  }

  void setPayFull(bool value) {
    if (state.value == null) return;
    state = AsyncData(state.value!.copyWith(payFull: value));
  }

  Future<void> confirmBooking({String? paymentPin}) async {
    final currentState = state.value;
    if (currentState == null || !currentState.canConfirm) return;

    final selectedDate = currentState.selectedDate!;
    final selectedTimeSlot = currentState.selectedTimeSlot!;
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final clientBookingId = const Uuid().v4();
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    // Set Loading
    state = AsyncData(currentState.copyWith(
      status: BookingStatus.locking,
      isLoading: true,
    ));

    try {
      // 1. Lock Slot
      final lockItem = BookingItem(
        id: clientBookingId,
        userId: userId,
        tutor: _tutor,
        date: selectedDate,
        timeSlot: selectedTimeSlot,
        totalPrice: _tutor.hourlyRate * 2,
        status: 'Locked',
        lockedUntil: DateTime.now().add(const Duration(minutes: 10)),
        type: currentState.bookingType,
        learningMode: currentState.learningMode,
      );

      final serverBookingId = await ref.read(bookingProvider.notifier).lockSlot(
        lockItem,
        type: currentState.bookingType,
        durationMonths: currentState.bookingType == 'long_term' ? currentState.durationMonths : null,
        daysOfWeek: currentState.bookingType == 'long_term' ? currentState.selectedDays : null,
        learningMode: currentState.learningMode,
        payFull: currentState.bookingType == 'long_term' ? currentState.payFull : true, // Single always pays full
        paymentPin: paymentPin,
      );
      if (serverBookingId.isEmpty) throw Exception("Server returned invalid Booking ID");

      // 2. Simulate Payment
      await Future.delayed(const Duration(seconds: 1));

      // 3. Confirm
      await ref.read(bookingProvider.notifier).confirmBooking(serverBookingId);

      // 4. Notify Tutor
      try {
        ref.read(chatControllerProvider(_tutor.id)).sendMessage(
          'Hệ thống: Bạn đã đặt lịch học thành công vào ngày $formattedDate, khung giờ $selectedTimeSlot.',
        );
      } catch (_) {}

      // 5. Refresh Data
      ref.invalidate(bookingProvider);

      // 6. Success
      if (state.value != null) {
        state = AsyncData(state.value!.copyWith(
          status: BookingStatus.success,
          bookingId: serverBookingId,
          isLoading: false,
        ));
      }
    } catch (e) {
      String userMessage = 'Đã xảy ra lỗi.';
      if (e is BookingException) {
        userMessage = e.userMessage;
      } else if (e is ApiException) userMessage = e.userMessage; // Simplify mapped logic here

      if (state.value != null) {
        state = AsyncData(state.value!.copyWith(
          status: BookingStatus.error,
          errorMessage: userMessage,
          isLoading: false,
        ));
      }
    }
  }

  void resetStatus() {
    if (state.value != null) {
        state = AsyncData(state.value!.copyWith(
        status: BookingStatus.idle,
        errorMessage: null,
        bookingId: null,
        ));
    }
  }

  // Helper methods for UI
  TimeSlotStatus getTimeSlotStatus(String timeSlot, DateTime date) {
    final existingBookings = ref.read(bookingProvider).value ?? [];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final dateStr = DateFormat('yyyyMMdd').format(date);

    for (var booking in existingBookings) {
      if (booking.tutor.id == _tutor.id &&
          DateFormat('yyyyMMdd').format(booking.date) == dateStr &&
          booking.timeSlot == timeSlot &&
          booking.status != 'Cancelled') {
        if (booking.status == 'Upcoming') {
          return TimeSlotStatus.booked;
        } else if (booking.status == 'Locked') {
          if (booking.lockedUntil != null && booking.lockedUntil!.isAfter(DateTime.now())) {
            return booking.userId == currentUserId 
                ? TimeSlotStatus.myLock 
                : TimeSlotStatus.lockedByOthers;
          }
        }
      }
    }
    return TimeSlotStatus.available;
  }
}
