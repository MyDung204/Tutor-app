<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Report;
use Faker\Factory as Faker;

class ReportSeeder extends Seeder
{
    public function run()
    {
        $faker = Faker::create('vi_VN');

        // Create 10 pending reports
        for ($i = 0; $i < 10; $i++) {
            Report::create([
                'reporter_id' => $faker->numberBetween(1, 20),
                'reporter_name' => $faker->name,
                'target_id' => $faker->numberBetween(1, 30),
                'target_name' => 'Gia sư ' . $faker->firstName,
                'reason' => $faker->randomElement(['Gia sư không đến dạy', 'Thu phí cao hơn thỏa thuận', 'Thái độ không tốt', 'Spam tin nhắn']),
                'description' => $faker->realText(100),
                'status' => 'pending',
                'type' => 'tutor_report'
            ]);
        }

        // Create 5 resolved reports
        for ($i = 0; $i < 5; $i++) {
            Report::create([
                'reporter_id' => $faker->numberBetween(1, 20),
                'reporter_name' => $faker->name,
                'target_id' => $faker->numberBetween(1, 30),
                'target_name' => 'Gia sư ' . $faker->firstName,
                'reason' => 'Hủy lớp không báo',
                'description' => $faker->realText(80),
                'status' => 'resolved',
                'type' => 'tutor_report'
            ]);
        }
    }
}
