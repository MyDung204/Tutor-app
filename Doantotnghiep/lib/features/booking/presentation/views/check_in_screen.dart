
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInScreen extends StatefulWidget {
  final String classId;
  const CheckInScreen({super.key, required this.classId});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isCheckingLocation = false;
  bool _isMockLocationDetected = false; // Simulation toggle
  bool _isCheckedIn = false;
  File? _evidencePhoto; // Mock photo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điểm danh (Check-in)')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Icon(
               _isCheckedIn ? Icons.check_circle : Icons.location_on, 
               size: 80, 
               color: _isCheckedIn ? Colors.green : Colors.blue
             ),
             const SizedBox(height: 24),
             
             Text(
               _isCheckedIn 
                  ? 'Đã điểm danh thành công!' 
                  : 'Đang túc trực tại lớp học?',
               textAlign: TextAlign.center,
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 8),
             Text(
               'Lớp học ID: ${widget.classId}',
               textAlign: TextAlign.center,
               style: const TextStyle(color: Colors.grey),
             ),
             const SizedBox(height: 48),

             if (!_isCheckedIn) ...[
               if (_isCheckingLocation)
                  const Center(child: CircularProgressIndicator())
               else if (_evidencePhoto == null)
                  ElevatedButton.icon(
                    onPressed: _performCheckIn,
                    icon: const Icon(Icons.my_location),
                    label: const Text('BẮT ĐẦU CHECK-IN GPS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  )
               else
                  _buildPhotoVerification(),
                  
               if (_isMockLocationDetected && _evidencePhoto == null) ...[
                 const SizedBox(height: 24),
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.red[50],
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.red),
                   ),
                   child: Column(
                     children: [
                       const Row(
                         children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(child: Text("CẢNH BÁO: PHÁT HIỆN GIẢ MẠO GPS!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                         ],
                       ),
                       const SizedBox(height: 8),
                       const Text("Hệ thống phát hiện bạn đang sử dụng Mock Location / Fake GPS."),
                       const SizedBox(height: 16),
                       OutlinedButton.icon(
                         onPressed: _takeEvidencePhoto,
                         icon: const Icon(Icons.camera_alt),
                         label: const Text("Chụp ảnh xác thực tại chỗ"),
                         style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                       )
                     ],
                   ),
                 )
               ]
             ],
          ],
        ),
      ),
    );
  }
  
  void _performCheckIn() async {
    setState(() => _isCheckingLocation = true);
    
    // Simulate GPS Check
    await Future.delayed(const Duration(seconds: 2));
    
    // MOCK LOGIC: Randomly detect Fake GPS for demo or force it here
    // Let's pretend we detected it for demonstration purposes if this is the first time
    // Or simpler: Toggle this via a hidden debug tap or just hardcode for the "Scenario"
    // Requirement says: "Tình huống: Gia sư dùng Fake GPS". So I will simulate detection = TRUE.
    
    setState(() {
      _isCheckingLocation = false;
      _isMockLocationDetected = true; // FORCE ERROR SCENARIO
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lỗi: Vị trí không tin cậy. Vui lòng xác thực thêm!'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _takeEvidencePhoto() async {
    // Simulate Camera
    setState(() => _isCheckingLocation = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isCheckingLocation = false;
      _evidencePhoto = File('path/to/mock/photo'); // Mock
    });
  }
  
  Widget _buildPhotoVerification() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.image, size: 50, color: Colors.grey),
              // Watermark
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.black54,
                  child: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}\nLat: 21.0285, Long: 105.8542',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
             setState(() => _isCheckedIn = true);
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in thành công với ảnh xác thực!')));
             // Add logic to save checkin to backend
          },
          child: const Text('Gửi xác thực & Check-in'),
        )
      ],
    );
  }
}
