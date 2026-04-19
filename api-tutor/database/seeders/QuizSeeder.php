<?php

namespace Database\Seeders;

use App\Models\Quiz;
use App\Models\User;
use Illuminate\Database\Seeder;

class QuizSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Find a tutor
        $tutor = User::where('role', 'tutor')->first();

        if (!$tutor) {
            return;
        }

        // Create a Math Quiz
        $quiz = Quiz::create([
            'tutor_id' => $tutor->id,
            'title' => 'Kiểm tra Toán 15 phút - Đại số',
            'description' => 'Bài kiểm tra nhanh kiến thức về phương trình bậc hai.',
            'time_limit_minutes' => 15,
            'is_published' => true,
        ]);

        // Question 1
        $q1 = $quiz->questions()->create([
            'content' => 'Nghiệm của phương trình x^2 - 4 = 0 là?',
            'points' => 1,
        ]);
        $q1->options()->createMany([
            ['content' => 'x = 2', 'is_correct' => false],
            ['content' => 'x = -2', 'is_correct' => false],
            ['content' => 'x = ±2', 'is_correct' => true],
            ['content' => 'Vô nghiệm', 'is_correct' => false],
        ]);

        // Question 2
        $q2 = $quiz->questions()->create([
            'content' => 'Biệt thức Delta của phương trình ax^2 + bx + c = 0 là?',
            'points' => 1,
        ]);
        $q2->options()->createMany([
            ['content' => 'b^2 + 4ac', 'is_correct' => false],
            ['content' => 'b^2 - 4ac', 'is_correct' => true],
            ['content' => '4ac - b^2', 'is_correct' => false],
            ['content' => 'b - 4ac', 'is_correct' => false],
        ]);
    }
}
