import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration
/// 
/// Quản lý cấu hình API cho các môi trường khác nhau:
/// - Android Emulator: 10.0.2.2 (trỏ về localhost của máy host)
/// - Physical Device: IP LAN của máy chạy server
/// - iOS Simulator: localhost
/// - Web: localhost
class ApiConfig {
  /// IP của máy chạy Laravel server
  /// 
  /// **Cách tìm IP LAN:**
  /// - Windows: Chạy `ipconfig` trong CMD, tìm "IPv4 Address"
  /// - Mac/Linux: Chạy `ifconfig` hoặc `ip addr`, tìm "inet"
  /// 
  /// **Ví dụ:** `192.168.1.100` hoặc `192.168.88.219`
  static const String serverIp = '192.168.5.2';
  
  /// Port của Laravel server (thường là 8000)
  static const int serverPort = 8000;
  
  /// Base URL cho API
  /// 
  /// Tự động detect platform và trả về URL phù hợp:
  /// - Android Emulator → `http://10.0.2.2:8000/api`
  /// - Physical Device → `http://[serverIp]:8000/api`
  /// - iOS Simulator → `http://localhost:8000/api`
  /// - Web → `http://localhost:8000/api`
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$serverPort/api';
    }
    
    if (Platform.isAndroid) {
      // Kiểm tra xem có đang chạy trên emulator không
      // Emulator: 10.0.2.2
      // Physical Device: dùng IP LAN
      // return 'http://10.0.2.2:$serverPort/api';
      
      // Nếu dùng Physical Device, uncomment dòng dưới và comment dòng trên:
      return 'http://$serverIp:$serverPort/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:$serverPort/api';
    }
    
    return 'http://localhost:$serverPort/api';
  }
  
  /// Timeout cho API requests (seconds)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}






