# 📡 HƯỚNG DẪN CẤU HÌNH API CHO ANDROID EMULATOR

## 🎯 Vấn đề

Khi chạy app Flutter trên **Android Emulator**, app không thể truy cập `localhost` hoặc `127.0.0.1` của máy host vì emulator chạy trong một môi trường network riêng.

## ✅ Giải pháp

### 1. **Android Emulator** → Dùng `10.0.2.2`

`10.0.2.2` là địa chỉ IP đặc biệt mà Android Emulator dùng để trỏ về `localhost` của máy host.

**Cấu hình hiện tại:**
```dart
// lib/core/network/api_config.dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api';  // ✅ Cho Emulator
  }
}
```

### 2. **Physical Device** → Dùng IP LAN

Khi test trên thiết bị thật, cần dùng IP LAN của máy chạy Laravel server.

**Cách tìm IP LAN:**

#### Windows:
```cmd
ipconfig
```
Tìm dòng **"IPv4 Address"** → Ví dụ: `192.168.88.219`

#### Mac/Linux:
```bash
ifconfig
# hoặc
ip addr
```
Tìm dòng **"inet"** → Ví dụ: `192.168.1.100`

**Cấu hình:**
```dart
// lib/core/network/api_config.dart
static const String serverIp = '192.168.88.219';  // ← Đổi IP này

// Để dùng Physical Device, uncomment:
if (Platform.isAndroid) {
  return 'http://$serverIp:8000/api';  // ✅ Cho Physical Device
}
```

### 3. **iOS Simulator** → Dùng `localhost`

iOS Simulator có thể truy cập trực tiếp `localhost` của máy host.

## 🔧 Cách sử dụng

### Option 1: Tự động (Đã cấu hình sẵn)

Code đã tự động detect platform:
- ✅ Android Emulator → `10.0.2.2:8000`
- ✅ iOS Simulator → `localhost:8000`
- ✅ Web → `localhost:8000`

### Option 2: Manual switch (Cho Physical Device)

Nếu muốn test trên **Physical Device**, sửa file `lib/core/network/api_config.dart`:

```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    // Emulator
    // return 'http://10.0.2.2:$serverPort/api';
    
    // Physical Device - Uncomment dòng này:
    return 'http://$serverIp:$serverPort/api';
  }
  // ...
}
```

## 📝 Checklist

- [ ] Laravel server đang chạy trên máy host (`php artisan serve`)
- [ ] Server listen trên `0.0.0.0:8000` (không phải `127.0.0.1`)
- [ ] Android Emulator → Dùng `10.0.2.2:8000`
- [ ] Physical Device → Dùng IP LAN (ví dụ: `192.168.88.219:8000`)
- [ ] Firewall không block port 8000

## 🚀 Test kết nối

### 1. Kiểm tra Laravel server:
```bash
# Trên máy host
php artisan serve --host=0.0.0.0 --port=8000
```

### 2. Test từ browser:
```
http://localhost:8000/api/tutors
```

### 3. Test từ Emulator:
- Mở app Flutter
- Thử login hoặc load danh sách tutors
- Xem logs trong console

## ⚠️ Lưu ý

1. **Firewall:** Đảm bảo Windows Firewall không block port 8000
2. **Network:** Máy và emulator/device phải cùng mạng LAN
3. **Server IP:** Nếu IP LAN thay đổi, cần update trong `api_config.dart`
4. **HTTPS:** Production nên dùng HTTPS thay vì HTTP

## 🔐 Production

Khi deploy production, nên dùng:
- Environment variables
- Config files (dev/staging/prod)
- HTTPS với SSL certificate

Ví dụ:
```dart
static String get baseUrl {
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  
  switch (env) {
    case 'prod':
      return 'https://api.tutorapp.com/api';
    case 'staging':
      return 'https://staging-api.tutorapp.com/api';
    default:
      return ApiConfig.baseUrl;  // Dev
  }
}
```






