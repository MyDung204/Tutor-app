<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder
{
    public function run()
    {
        // Create Default Users
        // Create Default Users
        \App\Models\User::updateOrCreate(
            ['email' => 'admin@gmail.com'],
            [
                'name' => 'Admin User',
                'password' => \Illuminate\Support\Facades\Hash::make('123456'),
                'role' => 'admin',
                'latitude' => 21.0285, // Hanoi
                'longitude' => 105.8542,
            ]
        );

        \App\Models\User::updateOrCreate(
            ['email' => 'tutor@gmail.com'],
            [
                'name' => 'Tutor A',
                'password' => \Illuminate\Support\Facades\Hash::make('123456'),
                'role' => 'tutor',
                'latitude' => 21.0285, // Hanoi
                'longitude' => 105.8542,
            ]
        );

        \App\Models\User::updateOrCreate(
            ['email' => 'student@gmail.com'],
            [
                'name' => 'Student A',
                'password' => \Illuminate\Support\Facades\Hash::make('123456'),
                'role' => 'student',
                'latitude' => 21.0285, // Hanoi
                'longitude' => 105.8542,
            ]
        );

        $this->call([
            TutorSeeder::class,
            StudentSeeder::class,
            WalletSeeder::class,
            ChatSeeder::class,
            DataPopulationSeeder::class,
            ReviewSeeder::class,
            QuestionSeeder::class,
            AuditLogSeeder::class,
            BadgeSeeder::class,
        ]);
    }
}
