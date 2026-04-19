<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Tutor;
use App\Models\User;
use Faker\Factory as Faker;

class TutorSeeder extends Seeder
{
    public function run()
    {
        // Safe delete
        foreach (Tutor::all() as $t) {
            $t->delete();
        }

        $faker = Faker::create('vi_VN');
        $subjects_list = ['Toán', 'Lý', 'Hóa', 'Văn', 'Anh', 'Sinh', 'Sử', 'Địa', 'Piano', 'Guitar', 'IELTS', 'TOEIC'];

        for ($i = 0; $i < 30; $i++) {
            $name = $faker->name;
            $email = "tutor" . ($i + 1) . "@example.com";

            // 1. Create User
            $user = User::create([
                'name' => $name,
                'email' => $email,
                'password' => bcrypt('123456'), // Universal password
                'role' => 'tutor',
                'avatar_url' => "https://i.pravatar.cc/150?u=" . ($i + 1),
            ]);

            // 2. Create Tutor linked to User
            Tutor::create([
                'user_id' => $user->id,
                'name' => $name,
                'avatar_url' => $user->avatar_url,
                'bio' => "Gia sư " . $name . " chuyên dạy " . $faker->randomElement($subjects_list) . ". " . $faker->realText(50),
                'hourly_rate' => $faker->numberBetween(10, 50) * 10000,
                'rating' => $faker->randomFloat(1, 4.0, 5.0),
                'review_count' => $faker->numberBetween(5, 200),
                'location' => $faker->randomElement(['Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng', 'Online']),
                'address' => $faker->city,
                'is_verified' => $faker->boolean(80),
                'subjects' => $faker->randomElements($subjects_list, $faker->numberBetween(1, 4)),
                'teaching_mode' => $faker->randomElements(['Online', 'Offline'], $faker->numberBetween(1, 2)),
                'weekly_schedule' => [
                    '2' => ['18:00 - 20:00'],
                    '4' => ['18:00 - 20:00'],
                    '6' => ['19:00 - 21:00']
                ]
            ]);
        }

        // Create 5 specific pending tutors for testing
        for ($i = 0; $i < 5; $i++) {
            $name = $faker->name;
            $email = "pending_tutor" . ($i + 1) . "@example.com";

            $user = User::create([
                'name' => $name,
                'email' => $email,
                'password' => bcrypt('123456'),
                'role' => 'tutor',
                'avatar_url' => "https://i.pravatar.cc/150?u=pending_" . $i,
            ]);

            Tutor::create([
                'user_id' => $user->id,
                'name' => $name,
                'avatar_url' => $user->avatar_url,
                'bio' => "Gia sư mới đăng ký, đang chờ duyệt. " . $faker->realText(30),
                'hourly_rate' => $faker->numberBetween(10, 30) * 10000,
                'rating' => 0,
                'review_count' => 0,
                'location' => 'Hà Nội',
                'address' => $faker->city,
                'is_verified' => false, // PENDING
                'subjects' => $faker->randomElements($subjects_list, 2),
                'teaching_mode' => ['Online'],
                'weekly_schedule' => []
            ]);
        }
    }
}
