<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Review;
use App\Models\User;
use App\Models\Tutor;

class ReviewSeeder extends Seeder
{
    public function run()
    {
        $student = User::where('role', 'student')->first();
        $tutors = Tutor::all();

        if ($student && $tutors->count() > 0) {
            foreach ($tutors as $tutor) {
                Review::create([
                    'tutor_id' => $tutor->id,
                    'reviewer_id' => $student->id,
                    'rating' => 5,
                    'comment' => 'Gia sư dạy rất dễ hiểu, nhiệt tình!',
                    'created_at' => now()->subDays(rand(1, 30))
                ]);

                Review::create([
                    'tutor_id' => $tutor->id,
                    'reviewer_id' => $student->id,
                    'rating' => 4,
                    'comment' => 'Bài giảng hay nhưng hơi nhanh.',
                    'created_at' => now()->subDays(rand(1, 30))
                ]);
            }
        }
    }
}
