<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class TutorRequestSeeder extends Seeder
{
    public function run()
    {
        // Find some student users (role 'student')
        $studentIds = DB::table('users')->where('role', 'student')->pluck('id')->toArray();

        if (empty($studentIds)) {
            $this->command->info('No students found, skipping TutorRequest seeding.');
            return;
        }

        $subjects = ['Toán', 'Lý', 'Hóa', 'Tiếng Anh', 'Văn', 'Sinh', 'Sử', 'Địa'];
        $grades = ['Lớp 1', 'Lớp 5', 'Lớp 9', 'Lớp 10', 'Lớp 12', 'Đại học'];
        $locations = ['Online', 'Hà Nội', 'TP.HCM', 'Đà Nẵng'];
        $schedules = ['Thứ 2, 4, 6 (18h-20h)', 'Thứ 3, 5, 7 (19h-21h)', 'Cuối tuần', 'Thỏa thuận'];

        $requests = [];

        for ($i = 0; $i < 20; $i++) {
            $minBudget = rand(100, 300) * 1000;
            $maxBudget = $minBudget + rand(50, 200) * 1000;

            $requests[] = [
                'student_id' => $studentIds[array_rand($studentIds)],
                'subject' => $subjects[array_rand($subjects)],
                'grade_level' => $grades[array_rand($grades)],
                'description' => 'Tôi cần tìm gia sư dạy kèm môn này, yêu cầu nhiệt tình và có kinh nghiệm.',
                'min_budget' => $minBudget,
                'max_budget' => $maxBudget,
                'schedule' => $schedules[array_rand($schedules)],
                'location' => $locations[array_rand($locations)],
                'status' => 'open',
                'created_at' => now()->subDays(rand(0, 30)),
                'updated_at' => now(),
            ];
        }

        DB::table('tutor_requests')->insert($requests);
    }
}
