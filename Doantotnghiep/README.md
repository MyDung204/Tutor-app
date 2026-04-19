# 🎓 App Gia Sư (Tutor Connection Platform)

Một nền tảng kết nối **Gia sư** và **Học viên** hiện đại, được xây dựng bằng **Flutter**. Ứng dụng cung cấp giải pháp toàn diện cho việc tìm kiếm, đặt lịch, và quản lý lớp học kèm (1-1 hoặc nhóm).

---

## 🌟 Giới thiệu chung

Dự án được thiết kế như một "Uber cho Gia sư", tập trung vào trải nghiệm người dùng mượt mà và giao diện hiện đại (**EduTheme**).

### 🎯 Vai trò người dùng
1.  **Học viên (Student)**: Tìm kiếm gia sư, đăng tin tìm người dạy, đặt lịch học, tham gia cộng đồng hỏi đáp.
2.  **Gia sư (Tutor)**: Quản lý lịch dạy, mở lớp học, tìm kiếm học viên, theo dõi thu nhập.
3.  **Admin (Quản trị viên)**: Phê duyệt hồ sơ gia sư, quản lý người dùng, xử lý báo cáo.

---

## 🚀 Tính năng Chuyên sâu (Deep Dive)

### 1. Phân hệ Học viên (Student Features)
Học viên là trung tâm của ứng dụng với quy trình "Find - Book - Learn" được tối ưu hóa.

*   **🔍 Tìm kiếm & Khám phá (Discovery)**:
    *   **Smart Search**: Tìm gia sư theo Môn học, Giá tiền, Khu vực, Giới tính, và Hình thức (Online/Offline).
    *   **Gợi ý cá nhân hóa**: Trang chủ hiển thị gia sư nổi bật và lớp học phù hợp.
    *   **Bản đồ**: Tìm gia sư quanh đây với bộ lọc bán kính (1-25km).

*   **📅 Đặt lịch thông minh (Booking Engine)**:
    *   **Single Session**: Đặt 1 buổi học lẻ theo lịch rảnh của gia sư.
    *   **Long-term Request**: Đăng ký khóa học dài hạn (theo tháng) với lịch cố định.
    *   **Kiểm soát xung đột**: Hệ thống tự động ngăn chặn đặt trùng lịch.

*   **💬 Cộng đồng & Hỏi đáp**:
    *   **Q&A Forum**: Đặt câu hỏi bài tập, nhận giải đáp từ cộng đồng.
    *   **Tutor Request**: Đăng yêu cầu tìm gia sư để các gia sư apply vào.

### 2. Phân hệ Gia sư (Tutor Features)
Gia sư được cung cấp bộ công cụ quản lý lớp học chuyên nghiệp (LMS mini).

*   **📊 Dashboard trực quan**:
    *   Theo dõi: Thu nhập, Số lớp đang dạy, Rating, Tin nhắn mới.
    *   Real-time Notifications: Nhận thông báo ngay lập tức khi có booking mới.

*   **🗓️ Quản lý Lịch dạy (Schedule Manager)**:
    *   **Hybrid Input**: Hỗ trợ chọn nhanh theo ca (Sáng/Chiều/Tối) hoặc chọn giờ cụ thể (Custom Time).
    *   **Sync**: Lịch dạy được đồng bộ hóa để học viên không thể đặt vào giờ bận.

*   **🏫 Quản lý Lớp học (Class Management)**:
    *   **Tạo lớp**: Mở lớp 1-1 hoặc lớp Nhóm, thiết lập học phí, mô tả chi tiết.
    *   **Duyệt học viên**: Chấp nhận hoặc từ chối yêu cầu tham gia lớp.
    *   **Jitsi Integration**: Tự động tạo link phòng học trực tuyến (Jitsi Meet) khi bắt đầu buổi học.

*   **💼 Tài chính (Financials)**:
    *   **Ví điện tử (Mock)**: Mô phỏng nạp/rút tiền, xem lịch sử giao dịch.
    *   **Nhắc nợ**: Gửi thông báo nhắc nhở đóng học phí tới học viên.

---

## 🛠️ Kiến trúc & Kỹ thuật (Technical Deep Dive)

Dự án sử dụng các công nghệ và pattern hiện đại nhất của Flutter ecosystem.

### 🏗️ Architecture
*   **Pattern**: MVVM (Model - View - ViewModel) kết hợp Clean Architecture.
*   **State Management**: `flutter_riverpod` (v2.x) với Code Generation (`@riverpod`).
*   **Navigation**: `go_router` (Hỗ trợ Deep Links và Nested Navigation).

### 📦 Key Packages
| Package | Mục đích |
| :--- | :--- |
| `flutter_riverpod` | Quản lý trạng thái toàn ứng dụng |
| `go_router` | Điều hướng màn hình |
| `dio` | Networking & API Client |
| `google_maps_flutter` | Hiển thị bản đồ và vị trí |
| `table_calendar` | Lịch biểu và chọn ngày |
| `image_picker` | Upload ảnh avatar/KYC |
| `shared_preferences` | Lưu trữ dữ liệu cục bộ đơn giản |

### 📂 Cấu trúc thư mục (`/lib`)
*   `core/`: Các utility dùng chung (Theme, Router, API Client, Constants).
*   `features/`: Chia tách theo tính năng (Modular structure).
    *   `auth/`: Đăng nhập, Đăng ký.
    *   `home/`: Màn hình chính.
    *   `search/`: Tìm kiếm.
    *   `booking/`: Logic đặt lịch.
    *   `tutor_dashboard/`: Các màn hình quản lý của gia sư.
    *   `student/`: Các màn hình cá nhân của học viên.
    *   `admin/`: Phân hệ quản trị.

---

### 🛠️ Phân hệ Backend API (`api-tutor`)

Backend được xây dựng bằng **Laravel Framework**, đóng vai trò là RESTful API server cấp quyền và xử lý nghiệp vụ phức tạp.

#### 🏗️ Tech Stack
*   **Framework**: Laravel 11.x / 12.x (Latest).
*   **Database**: MySQL (Primary), Firebase Firestore (Optional for Chat/Realtime).
*   **Auth**: Laravel Sanctum (Token-based Authentication).
*   **Real-time**: Firebase Cloud Messaging (FCM) cho thông báo đẩy.

#### 🔌 Key API Modules
*   **Auth & User**: Đăng ký, Đăng nhập, Quản lý Token, Update Profile.
*   **Booking Core**:
    *   `POST /bookings/lock`: Khóa slot (giữ chỗ) trước khi thanh toán.
    *   `POST /bookings/confirm` / `reject`: Xử lý trạng thái booking.
*   **Wallet System**:
    *   `WalletController`: Quản lý số dư, lịch sử giao dịch.
    *   `PIN Security`: API thiết lập và xác thực mã PIN bảo mật 6 số.
    *   `Payment Simulation`: Webhook giả lập để test luồng nạp tiền.
*   **Smart Matching**:
    *   Thuật toán gợi ý gia sư dựa trên khoảng cách (Location) và môn học.
*   **Admin Panel API**:
    *   Endpoints riêng biệt cho việc duyệt Gia sư (`approveTutor`), duyệt Khóa học, và xem Logs hệ thống.

---

## 📖 Hướng dẫn sử dụng (Quick Guide)

### Dành cho Học viên
1.  **Đăng ký/Đăng nhập** tài khoản.
2.  **Tìm gia sư**: Dùng thanh tìm kiếm hoặc lọc theo môn học.
3.  **Đặt lịch**: Chọn gia sư -> Chọn "Đặt lịch" -> Chọn giờ -> Xác nhận.
4.  **Vào học**: Đến giờ học, mở lịch trình -> Nhấn "Vào lớp" (Video Call).

### Dành cho Gia sư
1.  **Cập nhật hồ sơ**: Điền đầy đủ thông tin, bằng cấp, môn dạy.
2.  **Xác thực (KYC)**: Gửi ảnh CMND/CCCD để được duyệt (yêu cầu để mở lớp).
3.  **Thiết lập lịch**: Vào "Lịch dạy" -> Chọn các khung giờ rảnh.
4.  **Nhận booking**: Xem yêu cầu trong Dashboard -> Chấp nhận -> Bắt đầu dạy.

---
> **Note**: Một số tính năng như Thanh toán (Wallet) và Video Call đang ở chế độ **Simulation/Mock** để phục vụ demo.
