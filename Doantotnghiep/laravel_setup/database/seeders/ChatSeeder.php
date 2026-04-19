<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;

class ChatSeeder extends Seeder
{
    public function run()
    {
        // Ensure we have users
        $student = User::where('email', 'student@example.com')->first();
        $tutor = User::where('email', 'tutor@example.com')->first();
        $admin = User::where('email', 'admin@example.com')->first();

        if (!$student || !$tutor)
            return;

        // 1. Conversation Student <-> Tutor
        $conv1 = Conversation::create([
            'user1_id' => min($student->id, $tutor->id),
            'user2_id' => max($student->id, $tutor->id),
            'last_message' => 'Chào thầy, em muốn hỏi về lớp học.'
        ]);

        Message::create([
            'conversation_id' => $conv1->id,
            'sender_id' => $student->id,
            'content' => 'Chào thầy, em muốn hỏi về lớp học.',
            'is_read' => true
        ]);
        Message::create([
            'conversation_id' => $conv1->id,
            'sender_id' => $tutor->id,
            'content' => 'Chào em, em cần tư vấn gì nào?',
            'is_read' => true
        ]);

        // 2. Conversation Admin <-> Tutor
        if ($admin) {
            $conv2 = Conversation::create([
                'user1_id' => min($admin->id, $tutor->id),
                'user2_id' => max($admin->id, $tutor->id),
                'last_message' => 'Hệ thống xin chào.'
            ]);
            Message::create([
                'conversation_id' => $conv2->id,
                'sender_id' => $admin->id,
                'content' => 'Hệ thống xin chào. Hồ sơ của bạn đã được duyệt.',
                'is_read' => false
            ]);
        }
    }
}
