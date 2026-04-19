import 'package:doantotnghiep/features/booking/presentation/view_models/booking_view_model.dart';
import 'package:doantotnghiep/features/tutor/domain/models/tutor.dart';
import 'package:doantotnghiep/features/wallet/data/wallet_provider.dart';
import 'package:doantotnghiep/features/wallet/presentation/pin_input_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Review screen before confirming booking
/// Shows booking summary and allows user to confirm or go back
class BookingReviewScreen extends ConsumerWidget {
  final Tutor tutor;
  final double totalPrice;
  final String bookingType;
  // Single
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  // Long-term
  final int? durationMonths;
  final List<int>? selectedDays;
  final String? learningMode;
  final Map<int, List<String>>? longTermSchedule;

  const BookingReviewScreen({
    super.key,
    required this.tutor,
    required this.totalPrice,
    this.bookingType = 'single',
    this.selectedDate,
    this.selectedTimeSlot,
    this.durationMonths,
    this.selectedDays,
    this.learningMode,
    this.longTermSchedule,
  });

  String _getDayName(int day) {
    const map = {2: 'Thứ 2', 3: 'Thứ 3', 4: 'Thứ 4', 5: 'Thứ 5', 6: 'Thứ 6', 7: 'Thứ 7', 8: 'Chủ Nhật'};
    return map[day] ?? 'Thứ $day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // UI Logic
    bool isSingle = bookingType == 'single';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem lại đặt lịch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutor Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: tutor.avatarUrl.isNotEmpty
                          ? NetworkImage(tutor.avatarUrl)
                          : null,
                      onBackgroundImageError: (_, __) {},
                      child: tutor.avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutor.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tutor.location,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${tutor.rating} (${tutor.reviewCount} đánh giá)',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Booking Details
            Text(
              'Chi tiết đặt lịch',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (isSingle) ...[
                        _buildDetailRow(
                        context,
                        icon: Icons.calendar_today,
                        label: 'Ngày học',
                        value: selectedDate != null ? dateFormat.format(selectedDate!) : 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                        context,
                        icon: Icons.access_time,
                        label: 'Khung giờ',
                        value: selectedTimeSlot ?? 'N/A',
                        ),
                        const Divider(),
                        _buildDetailRow(
                        context,
                        icon: Icons.timer,
                        label: 'Thời lượng',
                        value: '2 giờ',
                        ),
                    ] else ...[
                        _buildDetailRow(
                        context,
                        icon: Icons.repeat,
                        label: 'Loại',
                        value: 'Đăng ký dài hạn',
                        ),
                        const Divider(),
                        _buildDetailRow(
                        context,
                        icon: Icons.calendar_month,
                        label: 'Thời gian',
                        value: '$durationMonths tháng',
                        ),
                        const Divider(),
                        _buildDetailRow(
                        context,
                        icon: Icons.class_,
                        label: 'Hình thức',
                        value: learningMode == 'online' ? 'Online' : 'Offline',
                        ),
                         const Divider(),
                        _buildDetailRow(
                        context,
                        icon: Icons.schedule,
                        label: 'Lịch học',
                        value: selectedDays?.map((d) => _getDayName(d)).join(', ') ?? '',
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Price Breakdown
            Text(
              'Chi phí (Ước tính)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildPriceRow(
                      context,
                      label: 'Giá mỗi giờ',
                      value: currencyFormat.format(tutor.hourlyRate),
                    ),
                    const SizedBox(height: 8),
                    if (isSingle)
                        _buildPriceRow(
                        context,
                        label: 'Số giờ',
                        value: '2 giờ',
                        )
                    else 
                         _buildPriceRow(
                        context,
                        label: 'Tổng thời lượng (ước tính)',
                        value: '${(durationMonths ?? 1) * 4 * (selectedDays?.length ?? 1) * 2} giờ',
                        ),
                    
                    const Divider(height: 24),
                    _buildPriceRow(
                      context,
                      label: 'Tổng cộng',
                      value: currencyFormat.format(totalPrice),
                      isTotal: true,
                    ),
                    if (!isSingle && (durationMonths ?? 0) >= 1) ...[
                        const Divider(),
                        Consumer(
                           builder: (context, ref, child) {
                              final payFull = ref.watch(bookingViewModelProvider(tutor).select((s) => s.value?.payFull ?? false));
                              final oneMonthPrice = totalPrice / (durationMonths ?? 1);
                              final upfront = payFull ? totalPrice : oneMonthPrice;
                              return _buildPriceRow(
                                 context,
                                 label: 'Thanh toán ngay',
                                 value: currencyFormat.format(upfront),
                                 isTotal: true,
                                 highlight: true,
                              );
                           }
                        )
                    ] else ...[
                        const Divider(),
                        _buildPriceRow(
                           context,
                           label: 'Thanh toán ngay',
                           value: currencyFormat.format(totalPrice),
                           isTotal: true,
                           highlight: true,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cancellation Policy
            if (!isSingle && (durationMonths ?? 0) >= 1) ...[
               // Payment Options
               Text(
                'Hình thức thanh toán',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
               ),
               const SizedBox(height: 16),
               Card(
                 child: Column(
                   children: [
                     Consumer(
                       builder: (context, ref, child) {
                         final payFull = ref.watch(bookingViewModelProvider(tutor).select((s) => s.value?.payFull ?? false));
                         return Column(
                           children: [
                             RadioListTile<bool>(
                               title: const Text('Thanh toán từng tháng'),
                               subtitle: const Text('Thanh toán tháng đầu tiên trước. Các tháng sau sẽ được nhắc thanh toán định kỳ.'),
                               value: false,
                               groupValue: payFull,
                               onChanged: (val) => ref.read(bookingViewModelProvider(tutor).notifier).setPayFull(val!),
                             ),
                             RadioListTile<bool>(
                               title: const Text('Thanh toán một lần'),
                               subtitle: Text('Thanh toán toàn bộ ${durationMonths} tháng.'),
                               value: true,
                               groupValue: payFull,
                               onChanged: (val) => ref.read(bookingViewModelProvider(tutor).notifier).setPayFull(val!),
                             ),
                           ],
                         );
                       },
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 24),
            ],

            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chính sách hủy',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bạn có thể hủy đặt lịch trước 12 giờ để được hoàn tiền 100%.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[900],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Quay lại'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        // 1. Check Wallet PIN Status
                        final walletState = ref.read(walletProvider).value;
                        if (walletState == null) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tải thông tin ví...')));
                           return;
                        }

                        // 2. If no PIN setup, prompt user
                        if (!walletState.hasPaymentPin) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Vui lòng thiết lập mã PIN thanh toán trong Ví trước khi đặt lịch.'), backgroundColor: Colors.orange)
                           );
                           return; // Optionally navigate to setup
                        }

                        // 3. Show PIN Modal
                        final pin = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => PinInputModal(
                             title: 'Nhập mã PIN để thanh toán',
                             onVerify: (pin) async {
                                final walletRepo = ref.read(walletProvider.notifier);
                                return await walletRepo.verifyPin(pin);
                             },
                          ),
                        );

                        if (pin != null && pin.isNotEmpty) {
                            // 4. Proceed with Booking
                            if (context.mounted) context.pop(); // Pop review screen
                            
                            final viewModel = ref.read(
                              bookingViewModelProvider(tutor).notifier,
                            );
                            viewModel.confirmBooking(paymentPin: pin);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Xác nhận & Thanh toán'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isTotal = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: (isTotal || highlight) ? null : Colors.grey[600],
                fontWeight: (isTotal || highlight) ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : (highlight ? 16 : null),
                color: highlight ? Colors.red : (isTotal ? Theme.of(context).primaryColor : null),
              ),
        ),
      ],
    );
  }
}

