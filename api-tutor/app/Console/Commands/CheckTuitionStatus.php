<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Services\FirebaseNotificationService;
use Carbon\Carbon;

class CheckTuitionStatus extends Command
{
    protected $signature = 'tuition:check';
    protected $description = 'Check tuition status, send notifications, and handle removal.';

    protected $notificationService;

    public function __construct(FirebaseNotificationService $notificationService)
    {
        parent::__construct();
        $this->notificationService = $notificationService;
    }

    public function handle()
    {
        $this->info('Starting Tuition Check...');

        // 1. Identify "New Month" dues (e.g., set Due Date if not set, or reset for new month)
        // Ideally this is done when they enroll (set first due date) or after payment (set next).
        // Here we assume `next_payment_due` is already populated.
        
        $today = Carbon::today();

        // 2. Notify for DUE payments (On Due Date)
        $dueEnrollments = DB::table('course_students')
            ->join('courses', 'course_students.course_id', '=', 'courses.id')
            ->where('course_students.status', 'approved')
            ->whereIn('course_students.payment_status', ['paid', 'trial'])
            ->whereDate('course_students.next_payment_due', '<=', $today) 
            ->select('course_students.id', 'course_students.user_id', 'course_students.course_id', 'courses.title', 'courses.price')
            ->get();

        foreach ($dueEnrollments as $enrollment) {
            DB::table('course_students')
                ->where('id', $enrollment->id)
                ->update(['payment_status' => 'due']);

            $this->notificationService->sendToUser(
                $enrollment->user_id,
                'Đóng học phí tháng mới',
                "Đã đến hạn đóng học phí cho lớp '{$enrollment->title}'. Vui lòng thanh toán để tiếp tục học.",
                'tuition_due',
                ['course_id' => $enrollment->course_id, 'amount' => $enrollment->price]
            );
            $this->info("Set DUE for user {$enrollment->user_id} in course {$enrollment->course_id}");
        }

        // 3. Handle Grace Period Expiry (The "3 days countdown" finished)
        $expiredGrace = DB::table('course_students')
            ->join('courses', 'course_students.course_id', '=', 'courses.id')
            ->where('course_students.payment_status', 'grace_period')
            ->where('course_students.grace_period_ends_at', '<=', Carbon::now())
            ->select('course_students.id', 'course_students.user_id', 'course_students.course_id', 'courses.title')
            ->get();

        foreach ($expiredGrace as $enrollment) {
            // Remove from class (or set to rejected/removed)
            DB::table('course_students')
                ->where('id', $enrollment->id)
                ->update(['status' => 'removed', 'payment_status' => 'overdue']); // Soft remove logic

            $this->notificationService->sendToUser(
                $enrollment->user_id,
                'Đã bị xóa khỏi lớp',
                "Bạn đã bị xóa khỏi lớp '{$enrollment->title}' do không hoàn thành học phí sau 3 ngày gia hạn.",
                'removed_from_class',
                ['course_id' => $enrollment->course_id]
            );
             $this->info("Removed user {$enrollment->user_id} from course {$enrollment->course_id}");
        }
        
        $this->info('Tuition Check Complete.');
    }
}
