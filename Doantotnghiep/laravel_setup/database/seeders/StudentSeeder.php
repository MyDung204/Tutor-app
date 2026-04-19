<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Faker\Factory as Faker;

class StudentSeeder extends Seeder
{
    public function run()
    {
        $faker = Faker::create('vi_VN');

        // Create 20 specific students with realistic data
        for ($i = 0; $i < 20; $i++) {
            $name = $faker->name;
            $email = 'student' . ($i + 1) . '@gmail.com'; // Keep simple emails for testing

            User::create([
                'name' => $name,
                'email' => $email,
                'password' => Hash::make('123456'),
                'role' => 'student',
                'avatar_url' => "https://i.pravatar.cc/150?u=" . ($i + 100), // Offsetavatar ID
                'phone_number' => $faker->phoneNumber,
                'address' => $faker->address,
                'bio' => "Học viên chăm chỉ, đang tìm gia sư môn " . $faker->randomElement(['Toán', 'Lý', 'Hóa', 'Anh']),
                'email_verified_at' => now(),
            ]);
        }
    }
}
