import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';

/// State class for Booking feature
class BookingState {
  final Tutor? tutor;
  final BookingStatus status;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final String? bookingId;
  final String? errorMessage;
  final bool isLoading;
  // Long-term fields
  final String bookingType; // 'single' | 'long_term'
  final int durationMonths;
  final List<int> selectedDays;
  final String learningMode; // 'online' | 'offline'
  final Map<int, List<String>> longTermSchedule; 
  final bool payFull; // New field

  const BookingState({
    this.tutor,
    required this.status,
    this.selectedDate,
    this.selectedTimeSlot,
    this.bookingId,
    this.errorMessage,
    this.isLoading = false,
    this.bookingType = 'single',
    this.durationMonths = 1,
    this.selectedDays = const [],
    this.learningMode = 'online',
    this.longTermSchedule = const {},
    this.payFull = false,
  });

  factory BookingState.initial({Tutor? tutor}) => BookingState(
        tutor: tutor,
        status: BookingStatus.idle,
        selectedDate: null,
        selectedTimeSlot: null,
      );

  BookingState copyWith({
    Tutor? tutor,
    BookingStatus? status,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    String? bookingId,
    String? errorMessage,
    bool? isLoading,
    String? bookingType,
    int? durationMonths,
    List<int>? selectedDays,
    String? learningMode,
    Map<int, List<String>>? longTermSchedule,
    bool? payFull,
  }) {
    return BookingState(
      tutor: tutor ?? this.tutor,
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
      bookingId: bookingId ?? this.bookingId,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      bookingType: bookingType ?? this.bookingType,
      durationMonths: durationMonths ?? this.durationMonths,
      selectedDays: selectedDays ?? this.selectedDays,
      learningMode: learningMode ?? this.learningMode,
      longTermSchedule: longTermSchedule ?? this.longTermSchedule,
      payFull: payFull ?? this.payFull,
    );
  }

  bool get canConfirm {
    if (isLoading) return false;
    if (status != BookingStatus.idle) return false;

    if (bookingType == 'single') {
      return selectedDate != null && selectedTimeSlot != null;
    } else {
      // Long-term check
      if (selectedDays.isEmpty) return false;
      // Must have at least one slot selected for each selected day? Or validation logic?
      // Requirement: user selects days and creating slots.
      // Assuming longTermSchedule must have entries for selected days.
      return longTermSchedule.isNotEmpty;
    }
  }
}

enum BookingStatus {
  idle,
  processing,
  locking,
  confirming,
  success,
  error,
}



