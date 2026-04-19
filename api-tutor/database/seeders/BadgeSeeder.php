<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Badge;
use App\Models\User;

class BadgeSeeder extends Seeder
{
    public function run()
    {
        $badges = [
            [
                'name' => 'Tài năng trẻ',
                'slug' => 'young-talent',
                'description' => 'Gia sư trẻ tuổi có thành tích xuất sắc',
                'color_hex' => '#4ADE80', // Green
                'icon_url' => 'https://ui-avatars.com/api/?name=TN&background=4ADE80&color=fff'
            ],
            [
                'name' => 'Gia sư Ngôi sao',
                'slug' => 'star-tutor',
                'description' => 'Được đánh giá 5 sao liên tục',
                'color_hex' => '#FBBF24', // Yellow/Gold
                'icon_url' => 'https://ui-avatars.com/api/?name=NS&background=FBBF24&color=fff'
            ],
            [
                'name' => 'Đã xác thực',
                'slug' => 'verified',
                'description' => 'Đã xác minh bằng cấp và danh tính',
                'color_hex' => '#3B82F6', // Blue
                'icon_url' => 'https://ui-avatars.com/api/?name=XT&background=3B82F6&color=fff'
            ],
            [
                'name' => 'Siêu Nhiệt tình',
                'slug' => 'dedicated',
                'description' => 'Phản hồi tin nhắn cực nhanh',
                'color_hex' => '#F472B6', // Pink
                'icon_url' => 'https://ui-avatars.com/api/?name=NT&background=F472B6&color=fff'
            ],
        ];

        foreach ($badges as $badgeData) {
            Badge::updateOrCreate(['slug' => $badgeData['slug']], $badgeData);
        }

        // Auto assign 'verified' badge to all tutors for demo
        $verifiedBadge = Badge::where('slug', 'verified')->first();
        $tutors = User::where('role', 'tutor')->get();

        foreach ($tutors as $tutor) {
            if (!$tutor->badges()->where('badge_id', $verifiedBadge->id)->exists()) {
                $tutor->badges()->attach($verifiedBadge->id);
            }
        }
        
        $this->command->info('Badges seeded successfully!');
    }
}
