
import 'package:flutter/material.dart';

class SchedulePickerModal extends StatefulWidget {
  final String? initialSchedule;

  const SchedulePickerModal({super.key, this.initialSchedule});

  @override
  State<SchedulePickerModal> createState() => _SchedulePickerModalState();
}

class _SchedulePickerModalState extends State<SchedulePickerModal> {
  final List<String> _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  // Map of Day -> Time. If a day is in the map, it is selected.
  final Map<String, TimeOfDay> _scheduleMap = {};

  @override
  void initState() {
    super.initState();
    _parseInitialSchedule();
  }

  void _parseInitialSchedule() {
    if (widget.initialSchedule == null || widget.initialSchedule!.isEmpty) return;
    
    final text = widget.initialSchedule!;
    // Heuristic parsing
    // Format 1: "T2: 19:00, T4: 18:00"
    // Format 2: "T2, T4 - 19:00" (Legacy)
    
    try {
      if (text.contains(' - ')) { // Legacy format check
         final parts = text.split(' - ');
         final daysPart = parts[0];
         final timePart = parts[1];
         
         final timeRegex = RegExp(r'(\d{1,2}):(\d{2})');
         final match = timeRegex.firstMatch(timePart);
         if (match != null) {
            final time = TimeOfDay(hour: int.parse(match.group(1)!), minute: int.parse(match.group(2)!));
            for (var d in _days) {
              if (daysPart.contains(d)) {
                _scheduleMap[d] = time;
              }
            }
         }
      } else {
        // Individual format: T2 19:00, T4 18:00
        // Or T2: 19:00
        // Simple regex: (T\d|CN)[:\s]+(\d{1,2}:\d{2})
        final regex = RegExp(r'(T\d|CN)[:\s]+(\d{1,2}:\d{2})');
        final matches = regex.allMatches(text);
        for (var m in matches) {
           final day = m.group(1)!;
           final timeStr = m.group(2)!;
           final tParts = timeStr.split(':');
           _scheduleMap[day] = TimeOfDay(hour: int.parse(tParts[0]), minute: int.parse(tParts[1]));
        }
      }
    } catch (e) {
      print('Error parsing schedule: $e');
    }
  }

  String _formatResult() {
    if (_scheduleMap.isEmpty) return '';

    // Sort days
    final sortedDays = _scheduleMap.keys.toList()
      ..sort((a, b) => _days.indexOf(a).compareTo(_days.indexOf(b)));

    // Check if all times are the same
    Set<String> times = {};
    for (var d in sortedDays) {
      final t = _scheduleMap[d]!;
      times.add('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }

    if (times.length == 1) {
       // All same time: T2, T4 - 19:00
       return '${sortedDays.join(', ')} - ${times.first}';
    } else {
       // Different times: T2 19:00, T4 18:00
       return sortedDays.map((d) {
         final t = _scheduleMap[d]!;
         final timeStr = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
         return '$d $timeStr';
       }).join(', ');
    }
  }

  Future<void> _handleDayTap(String day) async {
    if (_scheduleMap.containsKey(day)) {
      // If already selected, tap again to remove (as requested "an 2 lan moi la tich chon" interpreted as toggle)
      // OR specifically "an vao thu nao se duoc chon gio day"
      // Let's assume Tap on Selected -> Asking to Remove or Edit? 
      // User said "2 clicks to check/select", likely meaning toggle behavior.
      // Current standard: Tap Selected -> Remove.
      setState(() {
        _scheduleMap.remove(day);
      });
    } else {
      // Not selected -> Select and Pick Time
      final initialTime = TimeOfDay(hour: 19, minute: 0); // Default
      final picked = await showTimePicker(
        context: context, 
        initialTime: initialTime,
        helpText: 'Chọn giờ học cho $day'
      );
      
      if (picked != null) {
        setState(() {
          _scheduleMap[day] = picked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Chọn lịch học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ấn vào thứ để chọn giờ. Ấn lần nữa để bỏ chọn.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _days.map((day) {
              final isSelected = _scheduleMap.containsKey(day);
              final time = _scheduleMap[day];
              final label = isSelected 
                  ? '$day ${time!.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                  : day;

              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => _handleDayTap(day),
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue.shade900 : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _scheduleMap.isEmpty 
                  ? null 
                  : () => Navigator.pop(context, _formatResult()),
                child: const Text('Xác nhận'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
