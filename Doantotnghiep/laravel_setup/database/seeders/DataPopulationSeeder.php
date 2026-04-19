<?php
/**
 * Data Population Seeder
 * 
 * **Purpose:**
 * - Tạo dữ liệu mẫu cho các tính năng chính của hệ thống
 * - Bao gồm: Bookings, Courses, Study Groups, Enrollments, Members
 * 
 * **Data Created:**
 * - Bookings: Nhiều trạng thái (pending, upcoming, completed, cancelled)
 * - Courses: 15 lớp học với đầy đủ thông tin
 * - Study Groups: 15 nhóm học với đầy đủ thông tin
 * - Course Students: Enrollments cho courses
 * - Study Group Members: Members cho study groups
 * 
 * **Dependencies:**
 * - Phải chạy sau TutorSeeder và StudentSeeder
 * - Cần có ít nhất 1 tutor và 1 student
 */
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Models\Tutor;
use App\Models\Booking;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Course;
use App\Models\StudyGroup;
use Carbon\Carbon;
use Faker\Factory as Faker;

class DataPopulationSeeder extends Seeder
{
    public function run()
    {
        $faker = Faker::create('vi_VN');
        
        // Lấy users và tutors
        $student = User::where('email', 'student@gmail.com')->first();
        $students = User::where('role', 'student')->get();
        $tutor = Tutor::first();
        $tutors = Tutor::all();
        $tutorUser = User::where('email', 'tutor@gmail.com')->first();

        // ============================================
        // 1. SEED BOOKINGS (Nhiều trạng thái)
        // ============================================
        if ($student && $tutor) {
            // Upcoming booking (sắp diễn ra)
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->addDays(1)->setHour(14)->setMinute(0),
                'end_time' => Carbon::now()->addDays(1)->setHour(16)->setMinute(0),
                'status' => 'upcoming',
                'total_price' => 400000,
                'notes' => 'Ôn thi cuối kỳ môn Toán'
            ]);

            // Pending booking (chờ xác nhận)
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->addDays(3)->setHour(18)->setMinute(0),
                'end_time' => Carbon::now()->addDays(3)->setHour(20)->setMinute(0),
                'status' => 'pending',
                'total_price' => 350000,
                'notes' => 'Học thêm môn Lý'
            ]);

            // Completed bookings (lịch sử)
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->subDays(2)->setHour(9)->setMinute(0),
                'end_time' => Carbon::now()->subDays(2)->setHour(11)->setMinute(0),
                'status' => 'completed',
                'total_price' => 300000,
                'notes' => 'Luyện giải đề Lý'
            ]);

            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->subDays(5)->setHour(18)->setMinute(0),
                'end_time' => Carbon::now()->subDays(5)->setHour(20)->setMinute(0),
                'status' => 'completed',
                'total_price' => 450000,
                'notes' => 'Học tiếng Anh giao tiếp'
            ]);

            // Cancelled booking
            Booking::create([
                'tutor_id' => $tutor->id,
                'student_id' => $student->id,
                'start_time' => Carbon::now()->subDays(7)->setHour(14)->setMinute(0),
                'end_time' => Carbon::now()->subDays(7)->setHour(16)->setMinute(0),
                'status' => 'cancelled',
                'total_price' => 400000,
                'notes' => 'Đã hủy do bận việc'
            ]);

            // Tạo thêm bookings với các tutors khác (20 bookings)
            if ($tutors->count() > 1 && $students->count() > 0) {
                for ($i = 0; $i < 20; $i++) {
                    $randomTutor = $tutors->random();
                    $randomStudent = $students->random();
                    $daysOffset = $faker->numberBetween(-60, 60); // Lịch trong 2 tháng
                    $hour = $faker->numberBetween(8, 20);
                    
                    // Đảm bảo end_time không vượt quá 22h
                    $endHour = min($hour + 2, 22);
                    
                    // Xác định status dựa trên ngày
                    $status = 'pending';
                    if ($daysOffset < 0) {
                        // Quá khứ
                        $status = $faker->randomElement(['completed', 'completed', 'completed', 'cancelled']);
                    } elseif ($daysOffset == 0 || ($daysOffset > 0 && $daysOffset <= 7)) {
                        // Sắp tới (trong tuần này)
                        $status = $faker->randomElement(['upcoming', 'upcoming', 'pending']);
                    } else {
                        // Tương lai xa
                        $status = $faker->randomElement(['pending', 'upcoming']);
                    }
                    
                    Booking::create([
                        'tutor_id' => $randomTutor->id,
                        'student_id' => $randomStudent->id,
                        'start_time' => Carbon::now()->addDays($daysOffset)->setHour($hour)->setMinute(0),
                        'end_time' => Carbon::now()->addDays($daysOffset)->setHour($endHour)->setMinute(0),
                        'status' => $status,
                        'total_price' => $faker->numberBetween(200000, 500000),
                        'notes' => $faker->randomElement([
                            'Ôn thi cuối kỳ',
                            'Học thêm môn Toán',
                            'Luyện giải đề',
                            'Học tiếng Anh giao tiếp',
                            'Ôn tập bài cũ',
                            'Học bài mới',
                            'Luyện thi đại học',
                        ])
                    ]);
                }
            }
        }

        // ============================================
        // 2. SEED CHAT (Conversations & Messages)
        // ============================================
        // Tạo conversations giữa students và tutors
        $conversations = [];
        if ($students->count() > 0 && $tutors->count() > 0) {
            // Tạo 10 conversations
            for ($i = 0; $i < 10; $i++) {
                $randomStudent = $students->random();
                $randomTutor = $tutors->random();
                $tutorUserId = User::whereHas('tutor', function($q) use ($randomTutor) {
                    $q->where('id', $randomTutor->id);
                })->first();
                
                if (!$tutorUserId) continue;
                
                // Kiểm tra xem conversation đã tồn tại chưa
                $existingConv = Conversation::where(function($q) use ($randomStudent, $tutorUserId) {
                    $q->where('user1_id', $randomStudent->id)
                      ->where('user2_id', $tutorUserId->id);
                })->orWhere(function($q) use ($randomStudent, $tutorUserId) {
                    $q->where('user1_id', $tutorUserId->id)
                      ->where('user2_id', $randomStudent->id);
                })->first();
                
                if ($existingConv) {
                    $conversations[] = $existingConv;
                    continue;
                }
                
                $lastMessage = $faker->randomElement([
                    'Chào bạn, mình muốn hỏi về khóa học',
                    'Bạn có thể dạy môn Toán không?',
                    'Mình muốn đặt lịch học vào tuần sau',
                    'Cảm ơn bạn đã nhận lớp',
                    'Lịch học này có phù hợp không?',
                    'Mình muốn hỏi về học phí',
                ]);
                
                $conv = Conversation::create([
                    'user1_id' => $randomStudent->id,
                    'user2_id' => $tutorUserId->id,
                    'last_message' => $lastMessage,
                ]);
                
                $conversations[] = $conv;
                
                // Tạo 5-15 messages cho mỗi conversation
                $numMessages = $faker->numberBetween(5, 15);
                $messages = [
                    'Chào bạn, mình muốn hỏi về khóa học',
                    'Chào em, em cần hỗ trợ môn gì nhỉ?',
                    'Mình muốn học môn Toán lớp 12',
                    'Được ạ, mình có thể dạy Toán 12',
                    'Học phí như thế nào vậy ạ?',
                    'Học phí là 200k/buổi, mỗi buổi 2 giờ',
                    'Vậy mình có thể đặt lịch vào tối thứ 2, 4, 6 không?',
                    'Được ạ, tối 2-4-6 từ 19h-21h nhé',
                    'Cảm ơn bạn nhiều',
                    'Không có gì, hẹn gặp em nhé',
                ];
                
                for ($j = 0; $j < $numMessages; $j++) {
                    $senderId = $j % 2 == 0 ? $randomStudent->id : $tutorUserId->id;
                    $content = $faker->randomElement($messages);
                    
                    Message::create([
                        'conversation_id' => $conv->id,
                        'sender_id' => $senderId,
                        'content' => $content,
                        'is_read' => $faker->boolean(70), // 70% đã đọc
                        'created_at' => Carbon::now()->subDays($faker->numberBetween(0, 30))->subHours($faker->numberBetween(0, 23)),
                    ]);
                }
                
                // Cập nhật last_message
                $lastMsg = Message::where('conversation_id', $conv->id)->latest('created_at')->first();
                if ($lastMsg) {
                    $conv->update(['last_message' => $lastMsg->content]);
                }
            }
        }

        // ============================================
        // 3. SEED COURSES (Lớp học) - 15 courses
        // ============================================
        $subjects = ['Toán', 'Lý', 'Hóa', 'Văn', 'Tiếng Anh', 'Sinh', 'Sử', 'Địa', 'Piano', 'Guitar', 'IELTS', 'TOEIC'];
        $grades = ['Lớp 1', 'Lớp 5', 'Lớp 9', 'Lớp 10', 'Lớp 11', 'Lớp 12', 'Đại học'];
        $modes = ['Online', 'Offline'];
        $addresses = ['123 Nguyễn Huệ, Q.1, TP.HCM', '456 Lê Lợi, Q.3, TP.HCM', '789 Trần Hưng Đạo, Q.5, TP.HCM', 'Online'];
        $schedules = [
            'T2, T4, T6 (19:30 - 21:00)',
            'T3, T5, T7 (18:00 - 20:00)',
            'T2, T4 (19:00 - 21:00)',
            'T3, T5 (18:30 - 20:30)',
            'T6, CN (14:00 - 16:00)',
            'T2, T4, T6, CN (19:00 - 21:00)',
        ];

        $courses = [];
        if ($tutors->count() > 0) {
            for ($i = 0; $i < 15; $i++) {
                $randomTutor = $tutors->random();
                $subject = $faker->randomElement($subjects);
                $grade = $faker->randomElement($grades);
                $mode = $faker->randomElement($modes);
                $maxStudents = $faker->numberBetween(1, 10);
                
                $course = Course::create([
                    'tutor_id' => $randomTutor->id,
                    'title' => "Lớp {$subject} {$grade}",
                    'description' => $faker->realText(200),
                    'price' => $faker->numberBetween(1000000, 5000000),
                    'max_students' => $maxStudents,
                    'start_date' => Carbon::now()->addDays($faker->numberBetween(7, 60)),
                    'schedule' => $faker->randomElement($schedules),
                    'subject' => $subject,
                    'grade_level' => $grade,
                    'mode' => $mode,
                    'address' => $mode === 'Offline' ? $faker->randomElement($addresses) : null,
                    'status' => $faker->randomElement(['open', 'open', 'open', 'ongoing', 'closed']), // 75% open
                ]);
                
                $courses[] = $course;
            }
        }

        // ============================================
        // 4. SEED COURSE STUDENTS (Enrollments)
        // ============================================
        // Enroll một số students vào courses
        foreach ($courses as $course) {
            if ($students->count() > 0) {
                $numEnrollments = $faker->numberBetween(0, min(5, $course->max_students));
                $numToEnroll = min($numEnrollments, $students->count());
                
                if ($numToEnroll > 0) {
                    $enrolledStudents = $students->shuffle()->take($numToEnroll);
                    
                    foreach ($enrolledStudents as $student) {
                        // Kiểm tra xem đã enroll chưa
                        $exists = DB::table('course_students')
                            ->where('course_id', $course->id)
                            ->where('user_id', $student->id)
                            ->exists();
                        
                        if (!$exists) {
                            DB::table('course_students')->insert([
                                'course_id' => $course->id,
                                'user_id' => $student->id,
                                'enrolled_at' => Carbon::now()->subDays($faker->numberBetween(0, 30)),
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);
                        }
                    }
                }
            }
        }

        // ============================================
        // 5. SEED STUDY GROUPS (Học ghép) - 15 groups
        // ============================================
        $topics = [
            'Team work bài tập lớn Marketing',
            'Đôi bạn cùng tiến Toán 12',
            'Nhóm học IELTS',
            'Luyện thi THPT Quốc Gia',
            'Học nhóm môn Lý',
            'Ôn thi cuối kỳ Hóa',
            'Thực hành Piano',
            'Luyện giao tiếp Tiếng Anh',
            'Nhóm làm bài tập Văn',
            'Học nhóm môn Sinh',
        ];

        $studyGroups = [];
        if ($students->count() > 0) {
            for ($i = 0; $i < 15; $i++) {
                $creator = $students->random();
                $subject = $faker->randomElement($subjects);
                $grade = $faker->randomElement($grades);
                $maxMembers = $faker->numberBetween(2, 8);
                $pricePerSession = $faker->numberBetween(50000, 200000);
                
                $group = StudyGroup::create([
                    'creator_id' => $creator->id,
                    'topic' => $faker->randomElement($topics) . ' - ' . $subject,
                    'subject' => $subject,
                    'grade_level' => $grade,
                    'max_members' => $maxMembers,
                    'current_members' => 1, // Creator is first member
                    'description' => $faker->realText(150),
                    'location' => $faker->randomElement(['Online', 'Hà Nội', 'TP.HCM', 'Đà Nẵng', 'Q.1', 'Q.3', 'Q.5']),
                    'price' => $pricePerSession,
                    'status' => $faker->randomElement(['open', 'open', 'open', 'full', 'closed']), // 75% open
                ]);
                
                $studyGroups[] = $group;
                
                // Thêm creator vào study_group_members với status 'approved'
                DB::table('study_group_members')->insert([
                    'study_group_id' => $group->id,
                    'user_id' => $creator->id,
                    'status' => 'approved',
                    'joined_at' => Carbon::now()->subDays($faker->numberBetween(0, 30)),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }

        // ============================================
        // 6. SEED STUDY GROUP MEMBERS
        // ============================================
        // Thêm members vào study groups (một số approved, một số pending)
        foreach ($studyGroups as $group) {
            if ($students->count() > 1) {
                $numMembers = $faker->numberBetween(0, min(3, $group->max_members - 1)); // -1 vì đã có creator
                $numToAdd = min($numMembers, $students->count() - 1);
                
                if ($numToAdd > 0) {
                    $potentialMembers = $students->where('id', '!=', $group->creator_id)->shuffle()->take($numToAdd);
                    
                    foreach ($potentialMembers as $member) {
                        // Kiểm tra xem đã join chưa
                        $exists = DB::table('study_group_members')
                            ->where('study_group_id', $group->id)
                            ->where('user_id', $member->id)
                            ->exists();
                        
                        if (!$exists) {
                            $status = $faker->randomElement(['approved', 'pending', 'pending']); // 33% approved, 67% pending
                            
                            DB::table('study_group_members')->insert([
                                'study_group_id' => $group->id,
                                'user_id' => $member->id,
                                'status' => $status,
                                'joined_at' => $status === 'approved' ? Carbon::now()->subDays($faker->numberBetween(0, 20)) : null,
                                'created_at' => now(),
                                'updated_at' => now(),
                            ]);
                            
                            // Update current_members nếu approved
                            if ($status === 'approved') {
                                $group->increment('current_members');
                            }
                        }
                    }
                }
            }
        }

        $this->command->info('✅ Đã tạo dữ liệu mẫu:');
        $this->command->info('   - Bookings: ' . Booking::count() . ' lịch dạy');
        $this->command->info('   - Conversations: ' . Conversation::count() . ' cuộc trò chuyện');
        $this->command->info('   - Messages: ' . Message::count() . ' tin nhắn');
        $this->command->info('   - Courses: ' . Course::count() . ' lớp học');
        $this->command->info('   - Study Groups: ' . StudyGroup::count() . ' nhóm học');
    }
}
