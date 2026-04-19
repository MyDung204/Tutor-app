<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Tutor;

class TutorSeeder extends Seeder
{
    public function run()
    {
        // Xóa data cũ
        DB::table('tutors')->delete();

        Tutor::create([
            'name' => 'Nguyễn Văn Hùng',
            'avatar_url' => 'https://i.pravatar.cc/150?u=1',
            'bio' => 'Giáo viên Toán 10 năm kinh nghiệm, chuyên luyện thi Đại học.',
            'hourly_rate' => 200000,
            'rating' => 4.8,
            'review_count' => 120,
            'location' => 'Hà Nội',
            'address' => 'Cầu Giấy, Hà Nội',
            'gender' => 'Nam',
            'is_verified' => true,
            'subjects' => ['Toán', 'Lý'],
            'teaching_mode' => ['Online', 'Offline'],
            'weekly_schedule' => [
                '2' => ['08:00 - 10:00', '18:00 - 20:00'],
                '4' => ['08:00 - 10:00'],
                '6' => ['14:00 - 16:00']
            ]
        ]);

        Tutor::create([
            'name' => 'Trần Thị Mai',
            'avatar_url' => 'https://i.pravatar.cc/150?u=2',
            'bio' => 'Sinh viên Đại học Ngoại Ngữ, IELTS 8.0, nhận dạy tiếng Anh giao tiếp.',
            'hourly_rate' => 150000,
            'rating' => 4.5,
            'review_count' => 45,
            'location' => 'Hồ Chí Minh',
            'address' => 'Quận 1, HCM',
            'gender' => 'Nữ',
            'is_verified' => false,
            'subjects' => ['Tiếng Anh', 'Văn'],
            'teaching_mode' => ['Online'],
            'weekly_schedule' => [
                '3' => ['18:00 - 20:00'],
                '5' => ['18:00 - 20:00'],
                '7' => ['08:00 - 10:00', '14:00 - 16:00']
            ]
        ]);

        Tutor::create([
            'name' => 'Lê Quốc Bảo',
            'avatar_url' => 'https://i.pravatar.cc/150?u=3',
            'bio' => 'Cựu sinh viên Bách Khoa, chuyên gia lập trình và toán tư duy.',
            'hourly_rate' => 300000,
            'rating' => 5.0,
            'review_count' => 200,
            'location' => 'Đà Nẵng',
            'address' => 'Hải Châu, Đà Nẵng',
            'gender' => 'Nam',
            'is_verified' => true,
            'subjects' => ['Toán', 'Tin học', 'Hóa'],
            'teaching_mode' => ['Online', 'Offline'],
            'weekly_schedule' => [
                '8' => ['08:00 - 10:00', '10:00 - 12:00']
            ]
        ]);

        // Thêm 5 gia sư giả nữa
        for ($i = 4; $i <= 10; $i++) {
            Tutor::create([
                'name' => "Gia sư Test $i",
                'avatar_url' => "https://i.pravatar.cc/150?u=$i",
                'bio' => 'Gia sư nhiệt tình, có trách nhiệm.',
                'hourly_rate' => 100000 + ($i * 10000),
                'rating' => 4.0,
                'review_count' => $i * 5,
                'location' => 'Online',
                'subjects' => ['Toán', 'Anh'],
                'teaching_mode' => ['Online'],
            ]);
        }
    }
}
