<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder
{
    public function run()
    {
        // Create Default Users
        \App\Models\User::create([
            'name' => 'Admin User',
            'email' => 'admin@gmail.com',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
            'role' => 'admin'
        ]);

        \App\Models\User::create([
            'name' => 'Tutor A',
            'email' => 'tutor@gmail.com',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
            'role' => 'tutor'
        ]);

        \App\Models\User::create([
            'name' => 'Student A',
            'email' => 'student@gmail.com',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
            'role' => 'student'
        ]);

        $this->call([
            TutorSeeder::class,
            StudentSeeder::class,
            TutorRequestSeeder::class, // Thêm seeder cho tutor requests
            WalletSeeder::class,
            ChatSeeder::class,
            DataPopulationSeeder::class, // Tạo bookings, courses, study groups, enrollments, members
            ReviewSeeder::class,
            QuestionSeeder::class,
            ReportSeeder::class,
            AuditLogSeeder::class,
        ]);
    }
}
