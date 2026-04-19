<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Notification;
use App\Models\User;
use Carbon\Carbon;

class NotificationSeeder extends Seeder
{
    public function run()
    {
        $student = User::where('role', 'student')->first();
        $tutor = User::where('role', 'tutor')->first();

        // Seed for Student
        if ($student) {
            Notification::create([
                'user_id' => $student->id,
                'title' => 'Đặt lịch thành công',
                'body' => 'Gia sư Nguyễn Văn Hùng đã xác nhận yêu cầu học của bạn.',
                'type' => 'booking_confirmed',
                'data' => ['booking_id' => 1],
                'is_read' => false,
                'created_at' => Carbon::now()->subMinutes(30)
            ]);

            Notification::create([
                'user_id' => $student->id,
                'title' => 'Nhắc nhở lịch học',
                'body' => 'Bạn có lịch học Toán với gia sư Hùng vào ngày mai lúc 14:00.',
                'type' => 'booking_reminder',
                'data' => ['booking_id' => 1],
                'is_read' => true,
                'created_at' => Carbon::now()->subHours(5)
            ]);

            Notification::create([
                'user_id' => $student->id,
                'title' => 'Nạp tiền thành công',
                'body' => 'Bạn đã nạp thành công 500.000đ vào ví.',
                'type' => 'wallet',
                'data' => ['amount' => 500000],
                'is_read' => true,
                'created_at' => Carbon::now()->subDays(1)
            ]);
        }

        // Seed for Tutor
        if ($tutor) {
            Notification::create([
                'user_id' => $tutor->id,
                'title' => 'Yêu cầu nhận lớp mới',
                'body' => 'Học viên Trần Văn Nam đã gửi yêu cầu học môn Hóa.',
                'type' => 'class_request',
                'data' => ['request_id' => 1],
                'is_read' => false,
                'created_at' => Carbon::now()->subMinutes(15)
            ]);

            Notification::create([
                'user_id' => $tutor->id,
                'title' => 'Lịch dạy sắp tới',
                'body' => 'Bạn có lịch dạy lớp "Luyện thi Vật Lý 11" vào tối nay.',
                'type' => 'schedule_reminder',
                'data' => ['course_id' => 2],
                'is_read' => false,
                'created_at' => Carbon::now()->subHours(2)
            ]);
        }
    }
}
