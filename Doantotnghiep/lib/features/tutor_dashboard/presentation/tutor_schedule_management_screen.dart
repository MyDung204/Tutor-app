/// Tutor Schedule Management Screen
/// 
/// **Purpose:**
/// - Quản lý lịch dạy của gia sư
/// - Cho phép gia sư chọn các time slots rảnh trong tuần
/// 
/// **Features:**
/// - Xem lịch theo từng ngày trong tuần (Thứ 2 - Chủ Nhật)
/// - Chọn các time slots rảnh (08:00-10:00, 10:00-12:00, v.v.)
/// - Lưu lịch dạy (hiện tại là mock, cần tích hợp API)
/// 
/// **Time Slots:**
/// - 08:00 - 10:00
/// - 10:00 - 12:00
/// - 14:00 - 16:00
/// - 18:00 - 20:00
/// - 20:00 - 22:00
/// 
/// **TODO:**
/// - Tích hợp API để lưu lịch dạy
/// - Load lịch hiện tại từ backend
/// - Validate lịch dạy (không trùng với booking đã có)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';

/// Màn hình quản lý lịch dạy của gia sư
/// 
/// **Usage:**
/// - Truy cập từ tutor navigation → "Lịch dạy"
/// - Cho phép gia sư thiết lập lịch rảnh trong tuần
class TutorScheduleManagementScreen extends ConsumerStatefulWidget {
  const TutorScheduleManagementScreen({super.key});

  @override
  ConsumerState<TutorScheduleManagementScreen> createState() => _TutorScheduleManagementScreenState();
}

class _TutorScheduleManagementScreenState extends ConsumerState<TutorScheduleManagementScreen> {
  // Key mapping: '2' = Thứ 2, '3' = Thứ 3, ..., '8' = Chủ Nhật
  final Map<String, List<String>> _schedule = {
    '2': [], '3': [], '4': [], '5': [], '6': [], '7': [], '8': [],
  };

  final List<String> _timeSlots = [
    '08:00 - 10:00',
    '10:00 - 12:00',
    '14:00 - 16:00',
    '18:00 - 20:00',
    '20:00 - 22:00',
  ];

  final Map<String, String> _dayLabels = {
    '2': 'Thứ 2', '3': 'Thứ 3', '4': 'Thứ 4', '5': 'Thứ 5', '6': 'Thứ 6', '7': 'Thứ 7', '8': 'Chủ Nhật',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoading = true);
    try {
      final availabilities = await ref.read(tutorRepositoryProvider).getMyAvailability();
      
      // Clear current
    for (var key in _schedule.keys) {
      _schedule[key] = [];
    }

    // Populate
    for (var item in availabilities) {
      final day = item['day_of_week'].toString();
      final startTime = _parseTime(item['start_time'].toString());
      final endTime = _parseTime(item['end_time'].toString());
      final slot = '$startTime - $endTime';
      
      print('Parsed slot: $slot'); // Debug log
      
      if (_schedule.containsKey(day)) {
        if (_timeSlots.contains(slot)) {
           _schedule[day]!.add(slot);
        } else {
           // Handle custom slots if any? For now only predefined.
           _schedule[day]!.add(slot);
        }
      }
    }
    setState(() => _isLoading = false);
    } catch (e) {
      // print('DEBUG: Error in _fetchAvailability: $e\n$stack'); // Optional: keep silent or log to service
      setState(() => _isLoading = false);
    }
  }

  String _parseTime(String time) {
    if (time.isEmpty) return '00:00';
    try {
      final parts = time.split(':');
      final h = parts[0].padLeft(2, '0');
      final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      return '$h:$m';
    } catch (e) {
      return time.length >= 5 ? time.substring(0, 5) : time;
    }
  }

  Future<void> _showCustomTimePicker(String dayKey) async {
    // Pick Start Time
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Chọn giờ BẮT ĐẦU',
    );
    if (start == null) return;

    if (!mounted) return;

    // Pick End Time
    final TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour + 2, minute: start.minute),
      helpText: 'Chọn giờ KẾT THÚC',
    );
    if (end == null) return;

    // Validate
    final double startDouble = start.hour + start.minute / 60.0;
    final double endDouble = end.hour + end.minute / 60.0;

    if (endDouble <= startDouble) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giờ kết thúc phải sau giờ bắt đầu!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Format HH:mm
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    final slot = '$startStr - $endStr';

    setState(() {
      if (!_schedule[dayKey]!.contains(slot)) {
        _schedule[dayKey]!.add(slot);
        _schedule[dayKey]!.sort();
      }
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> apiPayload = [];
    _schedule.forEach((day, slots) {
      for (var slot in slots) {
        final times = slot.split(' - ');
        apiPayload.add({
          'day_of_week': int.parse(day),
          'start_time': '${times[0]}:00', // Append seconds
          'end_time': '${times[1]}:00',   // Append seconds
        });
      }
    });

    final success = await ref.read(tutorRepositoryProvider).updateAvailability(apiPayload);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu lịch dạy thành công!'), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu lịch dạy'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lịch dạy'),
        actions: [
          if (_isLoading)
             const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSchedule,
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: _dayLabels.length,
        itemBuilder: (context, index) {
          final dayKey = _dayLabels.keys.elementAt(index);
          final dayName = _dayLabels[dayKey]!;
          final currentSlots = _schedule[dayKey] ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  dayName, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142))
                ),
                subtitle: Text(
                  currentSlots.isEmpty ? 'Chưa có lịch' : '${currentSlots.length} ca dạy đã chọn',
                  style: TextStyle(
                    color: currentSlots.isEmpty ? Colors.grey[500] : const Color(0xFF4F5D75),
                    fontSize: 14
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: currentSlots.isEmpty ? Colors.grey[100] : const Color(0xFFE5E9FF),
                  child: Icon(
                    Icons.calendar_view_day_rounded, 
                    color: currentSlots.isEmpty ? Colors.grey[400] : const Color(0xFF4D6AFF),
                    size: 20,
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        
                        // Section 1: Selected Slots
                        if (currentSlots.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('Đã chọn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F5D75))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: currentSlots.map((slot) {
                              return Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4D6AFF).withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InputChip(
                                  label: Text(slot),
                                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  backgroundColor: const Color(0xFF4D6AFF),
                                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                                  onDeleted: () {
                                    setState(() {
                                      _schedule[dayKey]!.remove(slot);
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Section 2: Suggested Slots
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            const Text('Gợi ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F5D75))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _timeSlots.where((slot) => !currentSlots.contains(slot)).map((slot) {
                            return ActionChip(
                              label: Text(slot),
                              labelStyle: const TextStyle(color: Color(0xFF2D3142), fontSize: 13),
                              backgroundColor: const Color(0xFFF0F2F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                              onPressed: () {
                                setState(() {
                                  _schedule[dayKey]!.add(slot);
                                  _schedule[dayKey]!.sort(); 
                                });
                              },
                            );
                          }).toList(),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(height: 1),
                        ),

                        // Section 3: Add Custom Slot
                        Center(
                          child: InkWell(
                            onTap: () => _showCustomTimePicker(dayKey),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4D6AFF).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4D6AFF).withOpacity(0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.more_time_rounded, size: 20, color: Color(0xFF4D6AFF)),
                                  SizedBox(width: 10),
                                  Text(
                                    'Thêm khung giờ khác',
                                    style: TextStyle(
                                      color: Color(0xFF4D6AFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
