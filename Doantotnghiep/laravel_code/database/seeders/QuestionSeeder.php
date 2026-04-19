<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Question;
use App\Models\Answer;

class QuestionSeeder extends Seeder
{
    public function run()
    {
        DB::table('answers')->delete();
        DB::table('questions')->delete();

        $q1 = Question::create([
            'user_id' => 'u1',
            'user_name' => 'Học sinh A',
            'user_avatar' => 'https://i.pravatar.cc/150?u=10',
            'subject' => 'Toán',
            'content' => 'Làm sao để giải phương trình bậc 2 nhanh nhất ạ?',
            'image_url' => null,
            'like_count' => 5,
            'answer_count' => 1,
            'is_solved' => true
        ]);

        Answer::create([
            'question_id' => $q1->id,
            'user_id' => 't1',
            'user_name' => 'Thầy Hùng',
            'user_avatar' => 'https://i.pravatar.cc/150?u=1',
            'content' => 'Em có thể dùng máy tính Casio hoặc nhẩm nghiệm a+b+c=0 nhé.',
            'like_count' => 10,
            'is_accepted' => true
        ]);

        Question::create([
            'user_id' => 'u2',
            'user_name' => 'Bé Bông',
            'user_avatar' => 'https://i.pravatar.cc/150?u=11',
            'subject' => 'Tiếng Anh',
            'content' => 'Phân biệt "Make" và "Do" giúp em với mọi người ơi!',
            'like_count' => 2,
            'answer_count' => 0,
            'is_solved' => false
        ]);
    }
}
