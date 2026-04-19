<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\AuditLog;
use Faker\Factory as Faker;

class AuditLogSeeder extends Seeder
{
    public function run()
    {
        $faker = Faker::create('vi_VN');

        // 1. Create System Alerts (Warning/Danger)
        AuditLog::create([
            'title' => 'Phát hiện gian lận đặt lịch',
            'description' => 'Gia sư Nguyễn Văn A nhận 15 yêu cầu chỉ trong 1 phút.',
            'severity' => 'danger',
            'type' => 'alert'
        ]);

        AuditLog::create([
            'title' => 'Từ khóa nhạy cảm',
            'description' => 'Học viên B gửi tin nhắn chứa từ khóa cấm: "chuyển khoản ngoài".',
            'severity' => 'warning',
            'type' => 'alert'
        ]);

        // 2. Create Scan Logs (Info/Success)
        for ($i = 0; $i < 20; $i++) {
            AuditLog::create([
                'title' => 'AI Scan',
                'description' => 'Đã kiểm tra hội thoại #' . $faker->randomNumber(5) . ' - ' . $faker->randomElement(['An toàn.', 'An toàn.', 'An toàn.', 'Nghi vấn nhẹ.']),
                'severity' => 'success',
                'type' => 'scan_log',
                'created_at' => now()->subMinutes($i * 5)
            ]);
        }
    }
}
