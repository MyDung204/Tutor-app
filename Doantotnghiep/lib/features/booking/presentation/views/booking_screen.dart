import 'package:doantotnghiep/features/booking/domain/models/booking_state.dart';
import 'package:doantotnghiep/features/booking/presentation/view_models/booking_view_model.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:doantotnghiep/features/booking/data/booking_provider.dart';

/// Booking Screen - MVVM Pattern
/// View layer: Only handles UI rendering and user interactions
/// Business logic is handled by BookingViewModel
class BookingScreen extends ConsumerStatefulWidget {
  final Tutor tutor;

  const BookingScreen({super.key, required this.tutor});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late Tutor _tutor;

  @override
  void initState() {
    super.initState();
    _tutor = widget.tutor;
    // Initialize with current date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingViewModelProvider(_tutor).notifier)
          .selectDate(DateTime.now());
    });
  }

  Future<void> _onRefresh() async {
    try {
      // 1. Refresh Bookings (Waiting list)
      ref.refresh(bookingProvider);
      
      // 2. Fetch updated Tutor data (Schedule)
      final updatedTutor = await ref.read(tutorRepositoryProvider).getTutorById(_tutor.id);
      if (updatedTutor != null) {
        if (mounted) {
          setState(() {
            _tutor = updatedTutor;
          });
          // Reset view model with new tutor data
          ref.read(bookingViewModelProvider(_tutor).notifier).selectDate(DateTime.now());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lại dữ liệu: $e')),
        );
      }
    }
  }

  void _handleSuccess(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công!'),
        content: const Text('Yêu cầu đặt lịch của bạn đã được gửi. Bạn vui lòng vào đúng giờ nhé!'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.go('/schedule');
            },
            child: const Text('Xem Lịch học'),
          ),
        ],
      ),
    );
  }

  void _handleError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $errorMessage')),
    );
  }

  @override

  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingViewModelProvider(_tutor));
    final viewModelNotifier = ref.read(bookingViewModelProvider(_tutor).notifier);

    return bookingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Đã xảy ra lỗi: $error'))),
      data: (viewModel) {
        // Handle state changes for side effects (SnackBar/Dialog) using separate Listeners is better,
        // but for now keeping inline logic with null checks
        if (viewModel.status == BookingStatus.success && viewModel.bookingId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSuccess(viewModel.bookingId!);
            viewModelNotifier.resetStatus();
          });
        }

        if (viewModel.status == BookingStatus.error && viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleError(viewModel.errorMessage!);
            viewModelNotifier.resetStatus();
          });
        }

        final selectedDate = viewModel.selectedDate ?? DateTime.now();
        final selectedTimeSlot = viewModel.selectedTimeSlot;
        final isLoading = viewModel.isLoading;
        final canConfirm = viewModel.canConfirm;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Đặt lịch học'),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll is possible even if content is short
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tutor Info
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _tutor.avatarUrl.isNotEmpty 
                        ? NetworkImage(_tutor.avatarUrl) 
                        : null,
                    onBackgroundImageError: _tutor.avatarUrl.isNotEmpty 
                        ? (_, __) {} 
                        : null,
                    child: _tutor.avatarUrl.isEmpty 
                        ? const Icon(Icons.person, color: Colors.grey) 
                        : null,
                  ),
                  title: Text(_tutor.name),
                  subtitle: Text(
                    '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_tutor.hourlyRate)}/h',
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Booking Type Selector
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: SegmentedButton<String>(
                    segments: const [
                       ButtonSegment(value: 'single', label: Text('Một buổi'), icon: Icon(Icons.event)),
                       ButtonSegment(value: 'long_term', label: Text('Dài hạn'), icon: Icon(Icons.repeat)),
                    ],
                    selected: {viewModel.bookingType},
                    onSelectionChanged: (Set<String> newSelection) {
                       viewModelNotifier.setBookingType(newSelection.first);
                    },
                  ),
                ),

                if (viewModel.bookingType == 'single') ...[
                   // Date Picker
                   Text('Chọn ngày', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   CalendarDatePicker(
                     initialDate: selectedDate,
                     firstDate: DateTime.now(),
                     lastDate: DateTime.now().add(const Duration(days: 30)),
                     onDateChanged: (date) {
                       viewModelNotifier.selectDate(date);
                     },
                   ),
                   const SizedBox(height: 0),

                   // Time Slot Picker
                   Text('Chọn giờ học', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   _buildTimeSlotSelector(context, selectedDate, selectedTimeSlot, viewModelNotifier),
                ] else ...[
                   // Long Term UI
                   
                   // 1. Duration & Mode
                   Row(
                     children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text('Thời gian học', style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 8),
                             DropdownButtonFormField<int>(
                               initialValue: viewModel.durationMonths,
                               decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                               items: [1, 2, 3, 4, 5, 6].map((m) => DropdownMenuItem(value: m, child: Text('$m Tháng'))).toList(),
                               onChanged: (val) => viewModelNotifier.setDuration(val!),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text('Hình thức', style: TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(height: 8),
                             DropdownButtonFormField<String>(
                               initialValue: viewModel.learningMode,
                               decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                               items: const [
                                 DropdownMenuItem(value: 'online', child: Text('Online')),
                                 DropdownMenuItem(value: 'offline', child: Text('Offline')),
                               ],
                               onChanged: (val) => viewModelNotifier.setLearningMode(val!),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 24),

                   // 2. Weekly Schedule
                   Text('Lịch học trong tuần', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text('Chọn các ngày và giờ học bạn mong muốn:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                   const SizedBox(height: 16),
                   
                   ...['2','3','4','5','6','7','8'].map((dayKey) {
                      final dayInt = int.parse(dayKey);
                      final dayName = _getDayName(dayKey);
                      final availableSlots = _tutor.weeklySchedule[dayKey] ?? [];
                      
                      if (availableSlots.isEmpty) return const SizedBox.shrink();

                      final isDaySelected = viewModel.selectedDays.contains(dayInt);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: isDaySelected ? Theme.of(context).primaryColor : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: isDaySelected,
                          leading: Checkbox(
                            value: isDaySelected,
                            onChanged: (val) => viewModelNotifier.toggleDaySelection(dayInt),
                          ),
                          title: Text(dayName, style: TextStyle(fontWeight: isDaySelected ? FontWeight.bold : FontWeight.normal)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availableSlots.map((slot) {
                                  final isSlotSelected = viewModel.longTermSchedule[dayInt]?.contains(slot) ?? false;
                                  return FilterChip(
                                    label: Text(slot),
                                    selected: isSlotSelected,
                                    onSelected: isDaySelected ? (val) {
                                       viewModelNotifier.updateLongTermSchedule(dayInt, slot, val);
                                    } : null,
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      );
                   }),
                ],
              ],
            ),
          ),
        ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: canConfirm && !isLoading
                    ? () {
                        // Calculate duration
                        double durationHours = 2.0; // Default
                        if (viewModel.bookingType == 'single' && selectedTimeSlot != null) {
                           durationHours = _calculateDuration(selectedTimeSlot);
                        } else if (viewModel.bookingType == 'long_term') {
                           // Approx: Month * 4 weeks * 2 hours * Days
                           durationHours = (viewModel.durationMonths * 4 * viewModel.selectedDays.length * 2.0).toDouble(); 
                        }

                        // Navigate to review screen
                        context.push(
                          '/booking-review',
                          extra: {
                            'tutor': _tutor,
                            // Common fields
                            'totalPrice': _tutor.hourlyRate * durationHours,
                            
                            'bookingType': viewModel.bookingType,
                            
                            // Single
                            'date': selectedDate,
                            'timeSlot': selectedTimeSlot,
                            
                            // Long-term
                            'durationMonths': viewModel.durationMonths,
                            'selectedDays': viewModel.selectedDays,
                            'learningMode': viewModel.learningMode,
                            'longTermSchedule': viewModel.longTermSchedule,
                          },
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Xác nhận đặt lịch & Thanh toán'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSlotSelector(
    BuildContext context,
    DateTime selectedDate,
    String? selectedTimeSlot,
    BookingViewModel viewModel,
  ) {
    final weekday = selectedDate.weekday;
    final scheduleKey = (weekday == 7) ? '8' : (weekday + 1).toString();
    final availableSlots = _tutor.weeklySchedule[scheduleKey] ?? [];

    if (availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Gia sư không có lịch rảnh vào ngày này.',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableSlots.map((slot) {
            final status = viewModel.getTimeSlotStatus(slot, selectedDate);
            final isDisabled = status == TimeSlotStatus.booked ||
                status == TimeSlotStatus.lockedByOthers;
            final isSelected = selectedTimeSlot == slot;

            String label = slot;
            switch (status) {
              case TimeSlotStatus.booked:
                label += ' (Đã kín)';
                break;
              case TimeSlotStatus.lockedByOthers:
                label += ' (Đang giao dịch)';
                break;
              case TimeSlotStatus.myLock:
                label += ' (Bạn đang giữ)';
                break;
              case TimeSlotStatus.available:
                break;
            }

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: isDisabled
                  ? null
                  : (selected) {
                      if (selected) {
                        viewModel.selectTimeSlot(slot);
                      } else {
                        viewModel.selectTimeSlot(null);
                      }
                    },
              disabledColor: Colors.grey[300],
              selectedColor: status == TimeSlotStatus.myLock
                  ? Colors.orangeAccent
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
  double _calculateDuration(String timeSlot) {
    try {
      final parts = timeSlot.split(' - ');
      if (parts.length != 2) return 2.0;

      final start = DateFormat('HH:mm').parse(parts[0]);
      final end = DateFormat('HH:mm').parse(parts[1]);
      
      final diff = end.difference(start);
      return diff.inMinutes / 60.0;
    } catch (e) {
      return 2.0;
    }
  }

  String _getDayName(String key) {
    const map = {
      '2': 'Thứ 2', '3': 'Thứ 3', '4': 'Thứ 4', '5': 'Thứ 5',
      '6': 'Thứ 6', '7': 'Thứ 7', '8': 'Chủ Nhật'
    };
    return map[key] ?? key;
  }
}
