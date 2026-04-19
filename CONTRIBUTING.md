# Hướng dẫn đóng góp lỗi (Contributing Guidelines)

Cảm ơn bạn đã quan tâm và đóng góp cho **TutorApp**!

## Quy trình làm việc cơ bản

1. Cập nhật nhánh `main` mới nhất để tránh conflict (xung đột).
2. Tạo nhánh chức năng mới từ `main` với cú pháp: `feature/<tên-tính-năng>` hoặc `fix/<tên-lỗi>`.
   Ví dụ: `git checkout -b feature/tutor-statistics`
3. Commit sự thay đổi thường xuyên, mô tả commit rõ ràng.
4. Đẩy (Push) nhánh của bạn lên GitHub và tạo một Pull Request tới nhánh `main`.

## Quy tắc Code

* **Flutter**: Đảm bảo chạy `flutter format .` và kiểm tra lỗi thông qua `flutter analyze` trước khi commit.
* **Laravel**: Sử dụng PSR-12 standard, hãy chắc chắn kiểm tra cú pháp kỹ lưỡng.

🔗 Mọi câu hỏi vui lòng tạo issue mới để chúng ta cùng theo dõi!
