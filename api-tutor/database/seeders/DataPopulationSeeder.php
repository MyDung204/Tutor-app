<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Tutor;
use App\Models\Booking;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Course;
use App\Models\StudyGroup;
use Carbon\Carbon;

class DataPopulationSeeder extends Seeder
{
    public function run()
    {
        // 1. Seed Bookings
        $student = User::where('email', 'student@gmail.com')->first();
        $tutor = Tutor::first();

        if ($student && $tutor) {
            // Unchanged Upcoming
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->addDays(1)->setHour(14)->setMinute(0),
                'end_time' => Carbon::now()->addDays(1)->setHour(16)->setMinute(0),
                'status' => 'confirmed',
                'total_price' => 400000,
                'notes' => 'Ôn thi cuối kỳ môn Toán'
            ]);

            // History 1
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->subDays(2)->setHour(9)->setMinute(0),
                'end_time' => Carbon::now()->subDays(2)->setHour(11)->setMinute(0),
                'status' => 'completed',
                'total_price' => 300000,
                'notes' => 'Luyện giải đề Lý'
            ]);

            // History 2
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->subDays(5)->setHour(18)->setMinute(0),
                'end_time' => Carbon::now()->subDays(5)->setHour(20)->setMinute(0),
                'status' => 'completed',
                'total_price' => 450000,
                'notes' => 'Học tiếng Anh giao tiếp'
            ]);
        }

        // 2. Seed Chat (Conversation between Student & Tutor)
        if ($student) {
            $tutorUser = User::where('email', 'tutor@gmail.com')->first();
            if ($tutorUser) {
                $conv = Conversation::create([
                    'user1_id' => $student->id,
                    'user2_id' => $tutorUser->id,
                    'last_message' => 'Chào bạn, mình muốn hỏi về khóa học',
                ]);
                Message::create(['conversation_id' => $conv->id, 'sender_id' => $student->id, 'content' => 'Chào bạn, mình muốn hỏi về khóa học', 'is_read' => true]);
                Message::create(['conversation_id' => $conv->id, 'sender_id' => $tutorUser->id, 'content' => 'Chào em, em cần hỗ trợ môn gì nhỉ?', 'is_read' => false]);
            }
        }

        // 3. Seed Courses (Lớp học)
        if ($tutor) {
            Course::create([
                'tutor_id' => $tutor->id,
                'title' => 'Lớp Toán 12 Cấp Tốc',
                'description' => 'Luyện thi THPT Quốc Gia, cam kết 8+',
                'subject' => 'Toán',
                'grade_level' => 'Lớp 12',
                'price' => 2000000,
                'start_date' => Carbon::now()->addWeeks(1),
                'schedule' => 'T2, T4, T6 (19:30 - 21:00)',
                'status' => 'open'
            ]);
            Course::create([
                'tutor_id' => $tutor->id,
                'title' => 'Tiếng Anh Giao Tiếp Cơ Bản',
                'description' => 'Dành cho người mất gốc',
                'subject' => 'Tiếng Anh',
                'grade_level' => 'Người đi làm',
                'price' => 1500000,
                'start_date' => Carbon::now()->addWeeks(2),
                'schedule' => 'T3, T5 (18:00 - 20:00)',
                'status' => 'open'
            ]);
        }

        // 4. Seed Study Groups (Học ghép)
        if ($student) {
            StudyGroup::create([
                'creator_id' => $student->id,
                'topic' => 'Team work bài tập lớn Marketing',
                'subject' => 'Marketing',
                'grade_level' => 'Đại học',
                'max_members' => 5,
                'current_members' => 2,
                'description' => 'Cần tìm 3 bạn cùng làm bài tập lớn môn MKT căn bản.',
                'status' => 'open'
            ]);
            StudyGroup::create([
                'creator_id' => $student->id,
                'topic' => 'Đôi bạn cùng tiến Toán 12',
                'subject' => 'Toán',
                'grade_level' => 'Lớp 12',
                'max_members' => 2,
                'current_members' => 1,
                'description' => 'Tìm bạn học chung online mỗi tối.',
                'status' => 'open'
            ]);
        }
    }
}
