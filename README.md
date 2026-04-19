# TutorApp - Hệ Thống Quản Lý và Đặt Lịch Gia Sư 🎓

TutorApp là hệ thống nền tảng kết nối gia sư và học sinh, với đầy đủ các tính năng phục vụ cho việc quản lý học tập (LMS), đặt lịch học, trao đổi trực tuyến và thanh toán. 

Dự án này là kết quả của quá trình phát triển Đồ án tốt nghiệp / Dự án lớn, bao gồm hệ thống Backend mạnh mẽ và ứng dụng Mobile hiện đại.

---

## 🚀 Cấu Trúc Dự Án

Dự án được tổ chức theo dạng Monorepo, bao gồm 2 thành phần chính:

| Thư mục | Vai trò | Công nghệ chính |
| :--- | :--- | :--- |
| 📁 **[`api-tutor/`](./api-tutor)** | Backend & API Server | Laravel (PHP), MySQL |
| 📁 **[`Doantotnghiep/`](./Doantotnghiep)** | Ứng dụng Mobile (Học sinh & Gia sư) | Flutter (Dart) |

## ✨ Các Tính Năng Nổi Bật

Dự án đã phát triển và hoàn thiện được nhiều workflow chuyên sâu, tiêu biểu gồm có:
- **Hệ thống Quản lý khóa học (LMS):** Cung cấp xây dựng lộ trình bài học tuần tự, theo dõi tiến độ (video completion tracking > 90%).
- **Thống Kê Gia Sư:** Tính toán doanh thu, giờ dạy, học phí và đánh giá real-time.
- **eKYC & Phân Quyền (RBAC):** Admin-led eKYC duyệt thông tin gia sư, với hệ thống phân quyền phức tạp giữa Admin/Manager/Tutor/Student.
- **Hệ thống thanh toán:** Các quy trình xác thực, phiếu lệnh và xử lý thông tin học phí.
- **Giao diện quản lý & Sidebars:** Giao diện dashboard hiện đại với chế độ Dark mode hỗ trợ tương tác lọc dữ liệu đệ quy (recursive filters).

---

## 🛠 Công Nghệ Sử Dụng

*   **Backend:** PHP 8+, Laravel 10/11, MySQL
*   **Mobile App:** Flutter, Dart
*   **Version Control:** Git, GitHub

---

## ⚙️ Hướng Dẫn Cài Đặt (Local Environment)

Để chạy thử nghiệm toàn bộ hệ thống ở máy tính cá nhân, bạn cần cài đặt riêng biệt cho Frontend và Backend.

### 1. Khởi động Backend (`api-tutor`)

Yêu cầu: PHP >= 8.1, Composer, MySQL Server.

```bash
cd api-tutor

# 1. Copy file cấu hình môi trường
cp .env.example .env

# 2. Cài đặt các thư viện phụ thuộc
composer install

# 3. Tạo APP_KEY
php artisan key:generate

# 4. Chạy Migration và Seeder để tạo database (Nhớ cấu hình DB_ nội trong file .env trước mặt)
php artisan migrate --seed

# 5. Khởi động Server
php artisan serve
```

### 2. Khởi động Mobile App (`Doantotnghiep`)

Yêu cầu: Flutter SDK >= 3.x, Android Studio (hoặc Xcode cho môi trường iOS).

```bash
cd Doantotnghiep

# 1. Cải đặt các thư viện package
flutter pub get

# 2. Chạy ứng dụng trên giả lập hoặc thiết bị thực
flutter run
```

> **Lưu ý nhỏ:** Khi chạy App để test với backend Laravel trên máy ảo giả lập Android (Android Emulator), bạn có thể cần đổi địa chỉ gọi API thành `10.0.2.2` thay vì `127.0.0.1` hay `localhost`.

---

## 🛡️ License

Dự án thuộc bản quyền của nhà phát triển nội bộ. Mọi sao chép và tái sử dụng cho mục đích thương mại cần tuân theo các quy định được phép. Mọi đóng góp xin gửi Pull Request thông qua kho lưu trữ này.
