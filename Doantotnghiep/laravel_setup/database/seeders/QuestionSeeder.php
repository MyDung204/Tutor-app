<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use App\Models\User;

class QuestionSeeder extends Seeder
{
    public function run()
    {
        $student = User::where('role', 'student')->first();
        if (!$student)
            return;

        $questions = [
            [
                'user_id' => $student->id,
                'content' => 'Làm sao để giải phương trình lượng giác lớp 11 nhanh nhất?',
                'subject' => 'Toán',
                'tags' => json_encode(['Toán 11', 'Lượng giác']),
                'like_count' => 5,
                'answer_count' => 2,
                'created_at' => Carbon::now()->subHours(2),
                'updated_at' => Carbon::now()->subHours(2),
            ],
            [
                'user_id' => $student->id,
                'content' => 'Có ai biết trung tâm tiếng Anh nào tốt ở Hà Nội không ạ?',
                'subject' => 'Tiếng Anh',
                'tags' => json_encode(['Tiếng Anh', 'Tư vấn']),
                'like_count' => 12,
                'answer_count' => 5,
                'created_at' => Carbon::now()->subDays(1),
                'updated_at' => Carbon::now()->subDays(1),
            ],
            [
                'user_id' => $student->id,
                'content' => 'Cần tìm tài liệu ôn thi THPT Quốc gia môn Lý.',
                'subject' => 'Vật Lý',
                'tags' => json_encode(['Vật Lý', 'Tài liệu']),
                'like_count' => 8,
                'answer_count' => 1,
                'created_at' => Carbon::now()->subDays(3),
                'updated_at' => Carbon::now()->subDays(3),
            ]
        ];

        DB::table('questions')->insert($questions);
    }
}
