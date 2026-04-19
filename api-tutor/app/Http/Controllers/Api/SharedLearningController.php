<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\StudyGroup;
use App\Models\Course;
use Illuminate\Http\Request;

class SharedLearningController extends Controller
{
    protected $notificationService;

    public function __construct(\App\Services\FirebaseNotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    // Get all Study Groups (Học ghép)
    public function indexGroups(Request $request)
    {
        \Log::info('indexGroups called');
        $query = StudyGroup::with('creator')->where('status', '!=', 'closed')->latest();
        $groups = $query->get();

        if ($user = $request->user('sanctum')) {
            \Log::info('User authenticated: ' . $user->id);
            $memberStatus = \DB::table('study_group_members')
                ->where('user_id', $user->id)
                ->pluck('status', 'study_group_id');

            \Log::info('MemberStatus: ' . $memberStatus);

            $groups = $groups->map(function ($group) use ($memberStatus, $user) {
                $data = $group->toArray();
                $data['membership_status'] = $memberStatus[$group->id] ?? null;
                
                // Calculate confirmed members count
                $approvedCount = \DB::table('study_group_members')
                    ->where('study_group_id', $group->id)
                    ->where('status', 'approved')
                    ->count();
                // Add creator if not already in members table (usually is, but for safety)
                // Actually creator should be in members table as 'approved' or 'creator'
                
                $data['current_members'] = $APPROVED_COUNT_LOGIC_HERE ?? $approvedCount; // Let's just use the query result
                $data['current_members'] = $approvedCount;

                // --- NEW: Add Notification Logic ---
                $data['pending_requests_count'] = 0;
                $data['has_new_messages'] = false; 

                // Logic: If user is creator, count pending requests
                if ($group->creator_id == $user->id) {
                     $pendingCount = \DB::table('study_group_members')
                        ->where('study_group_id', $group->id)
                        ->where('status', 'pending')
                        ->count();
                     $data['pending_requests_count'] = $pendingCount;
                }
                
                \Log::info("Group {$group->id} status: " . ($data['membership_status'] ?? 'null'));
                return $data;
            });
        } else {
            \Log::info('User NOT authenticated');
        }

        return $groups;
    }

    // Get all Courses (Lớp học)
    /// 
    /// **Purpose:**
    /// - Lấy danh sách tất cả lớp học đang mở
    /// - Thêm enrollment status nếu user đã đăng nhập
    /// - Thêm danh sách học viên đã đăng ký (nếu là tutor của lớp)
    /// 
    /// **Returns:**
    /// - List of courses với thông tin enrollment status
    public function indexCourses(Request $request)
    {
        $user = $request->user('sanctum');

        $courses = Course::with(['tutor:id,user_id,name,phone', 'tutor.user:id,phone_number,email'])
            ->whereIn('status', ['open', 'ongoing'])
            ->latest()
            ->get();

        if ($user) {
            // Get detailed enrollment data
            $enrollments = \DB::table('course_students')
                ->where('user_id', $user->id)
                ->where('status', 'approved')
                ->get()
                ->keyBy('course_id');

            $enrolledCourseIds = $enrollments->keys()->toArray();

            $courses = $courses->map(function ($course) use ($user, $enrolledCourseIds, $enrollments) {
                $data = $course->toArray();
                $data['is_enrolled'] = in_array($course->id, $enrolledCourseIds);
                
                // Add Payment Status info for enrolled students
                if ($data['is_enrolled']) {
                    $enrollment = $enrollments[$course->id];
                    $data['payment_status'] = $enrollment->payment_status; // 'paid', 'due', 'grace_period', 'overdue'
                    $data['grace_period_ends_at'] = $enrollment->grace_period_ends_at;
                    
                    // Frontend can use this to block access
                    if ($enrollment->payment_status === 'grace_period' && $enrollment->grace_period_ends_at) {
                         $ends = \Carbon\Carbon::parse($enrollment->grace_period_ends_at);
                         if ($ends->isFuture()) {
                             $data['grace_remaining_seconds'] = $ends->diffInSeconds(now());
                         } else {
                             $data['grace_remaining_seconds'] = 0;
                         }
                    }
                }

                if ($course->tutor_id == $user->id) {
                    $students = \DB::table('course_students')
                        ->join('users', 'course_students.user_id', '=', 'users.id')
                        ->where('course_students.course_id', $course->id)
                        ->where('course_students.status', 'approved')
                        ->select('users.id', 'users.name', 'users.phone_number', 'users.email', 'course_students.enrolled_at', 'course_students.payment_status')
                        ->get()
                        ->toArray();

                    $data['students'] = $students;
                } else {
                    $studentCount = \DB::table('course_students')
                        ->where('course_id', $course->id)
                        ->where('status', 'approved')
                        ->count();

                    $data['student_count'] = $studentCount;
                    $data['students'] = [];
                }

                return $data;
            });
        } else {
            $courses = $courses->map(function ($course) {
                $data = $course->toArray();
                $studentCount = \DB::table('course_students')
                    ->where('course_id', $course->id)
                    ->where('status', 'approved')
                    ->count();

                $data['student_count'] = $studentCount;
                $data['students'] = [];
                $data['is_enrolled'] = false;
                return $data;
            });
        }

        return $courses;
    }

    // Refuse Tuition (Trigger Grace Period)
    public function refuseTuition(Request $request, $courseId)
    {
        $user = $request->user();
        
        $enrollment = \DB::table('course_students')
            ->where('course_id', $courseId)
            ->where('user_id', $user->id)
            ->first();

        if (!$enrollment) {
            return response()->json(['message' => 'Not enrolled.'], 404);
        }

        if ($enrollment->payment_status !== 'due') {
             return response()->json(['message' => 'Học phí chưa đến hạn hoặc đã xử lý.'], 400);
        }

        // Trigger 3-day countdown
        $graceEnds = now()->addDays(3);

        \DB::table('course_students')
            ->where('id', $enrollment->id)
            ->update([
                'payment_status' => 'grace_period',
                'grace_period_ends_at' => $graceEnds
            ]);

        return response()->json([
            'message' => 'Đã xác nhận từ chối. Bạn có 3 ngày để xử lý trước khi bị xóa khỏi lớp.',
            'grace_period_ends_at' => $graceEnds
        ]);
    }

    // Create a Course (Tạo lớp học mới)
    /// 
    /// **Purpose:**
    /// - Creates a new course for the authenticated tutor
    /// 
    /// **Parameters:**
    /// - `title`, `subject`, `grade_level`, `description`, `price`, `max_students`
    /// - `schedule`, `mode`, `address`, `start_date`
    /// 
    /// **Returns:**
    /// - `Course`: Created course object
    /// 
    public function storeCourse(Request $request)
    {
        $user = $request->user('sanctum');
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Validate
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'subject' => 'required|string',
            'grade_level' => 'required|string',
            'description' => 'required|string',
            'price' => 'required|numeric',
            'max_students' => 'required|integer|min:1',
            'schedule' => 'required|string',
            'mode' => 'required|in:Online,Offline',
            'address' => 'nullable|string', // Required if mode is Offline, but handled by logic or UI
            'start_date' => 'required|date',
        ]);

        // Check KYC
        $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
        if (!$tutor || !$tutor->is_verified) {
             return response()->json(['message' => 'Bạn cần xác thực tài khoản (KYC) để tạo lớp học.'], 403);
        }

        // Create Course
        $course = Course::create([
            'tutor_id' => $tutor->id, // Use Tutor ID, not User ID
            ...$validated,
            'status' => 'pending', // Default to pending approval
        ]);

        return response()->json($course, 201);
    }

    // Create a Study Group
    public function storeGroup(Request $request)
    {
        $validated = $request->validate([
            'topic' => 'required|string',
            'subject' => 'required|string',
            'grade_level' => 'required|string',
            'max_members' => 'required|integer',
            'description' => 'required|string',
        ]);

        $group = StudyGroup::create([
            'creator_id' => $request->user()->id,
            ...$validated,
            'current_members' => 1,
            'status' => 'open'
        ]);

        // Add creator as member
        \DB::table('study_group_members')->insert([
            'study_group_id' => $group->id,
            'user_id' => $request->user()->id,
            'status' => 'approved',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json($group, 201);
    }
    
    // Update a Study Group
    public function updateGroup(Request $request, $id)
    {
        $group = StudyGroup::findOrFail($id);
        if ($group->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Bạn không có quyền sửa nhóm này.'], 403);
        }

        $validated = $request->validate([
            'topic' => 'required|string',
            'subject' => 'required|string',
            'grade_level' => 'required|string',
            'max_members' => 'required|integer',
            'description' => 'required|string',
            'price' => 'nullable|numeric',
            'location' => 'nullable|string',
        ]);

        $group->update($validated);

        // Map price payload to price_per_session if needed. Actually backend migration 
        // probably named it price_per_session. Let's check what UI passes. 
        // UI passes 'price'. We map it.
        if ($request->has('price')) {
             $group->price_per_session = $request->input('price');
        }
        if ($request->has('location')) {
             $group->location = $request->input('location');
        }
        $group->save();

        return response()->json($group, 200);
    }
    // Join a Study Group
    public function joinGroup(Request $request, $id)
    {
        $group = StudyGroup::findOrFail($id);
        $user = $request->user();

        // Check if creator
        if ($group->creator_id === $user->id) {
            return response()->json(['message' => 'Bạn là chủ nhóm.'], 400);
        }

        // Check if already a member
        $existing = \DB::table('study_group_members')
            ->where('study_group_id', $id)
            ->where('user_id', $user->id)
            ->first();

        if ($existing) {
            // Allow re-join if previously rejected
            if ($existing->status === 'rejected') {
                if ($group->current_members >= $group->max_members) {
                     return response()->json(['message' => 'Nhóm đã đủ thành viên.'], 400);
                }

                \DB::table('study_group_members')
                    ->where('id', $existing->id)
                    ->update([
                        'status' => 'pending',
                        'updated_at' => now(),
                    ]);

                    // Notify Creator
            try {
                \Log::info("Sending Re-join Notification to Creator: {$group->creator_id}");
                $this->notificationService->sendToUser(
                    $group->creator_id,
                    'Yêu cầu tham gia lại',
                    "{$user->name} muốn tham gia lại nhóm '{$group->topic}'",
                    'group_request',
                    ['group_id' => $id]
                );
            } catch (\Exception $e) {
                \Log::error("Failed to send notification in joinGroup (re-join): " . $e->getMessage());
            }

            return response()->json(['message' => 'Đã gửi lại yêu cầu tham gia. Chờ duyệt.']);
        }
        return response()->json(['message' => 'Bạn đã tham gia hoặc đang chờ duyệt.'], 400);
    }

    if ($group->current_members >= $group->max_members) {
        return response()->json(['message' => 'Nhóm đã đủ thành viên.'], 400);
    }

    // Add to members table as pending
    \DB::table('study_group_members')->insert([
        'study_group_id' => $id,
        'user_id' => $user->id,
        'status' => 'pending',
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    // Notify Creator
    try {
        \Log::info("Sending Join Notification to Creator: {$group->creator_id}");
        $this->notificationService->sendToUser(
            $group->creator_id,
            'Yêu cầu tham gia nhóm',
            "{$user->name} muốn tham gia nhóm '{$group->topic}'",
            'group_request',
            ['group_id' => $id]
        );
    } catch (\Exception $e) {
         \Log::error("Failed to send notification in joinGroup: " . $e->getMessage());
    }

    return response()->json(['message' => 'Đã gửi yêu cầu tham gia. Chờ trưởng nhóm duyệt.']);
}

// Approve Member (Creator Only)
public function approveMember(Request $request, $groupId, $userId)
{
        $group = StudyGroup::findOrFail($groupId);

        if ($group->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($group->current_members >= $group->max_members) {
            return response()->json(['message' => 'Nhóm đã đầy.'], 400);
        }

        $member = \DB::table('study_group_members')
            ->where('study_group_id', $groupId)
            ->where('user_id', $userId)
            ->first();

        if (!$member) {
            return response()->json(['message' => 'Member not found'], 404);
        }

        \DB::table('study_group_members')
            ->where('id', $member->id)
            ->update(['status' => 'approved']);

        // Increment count
        $group->increment('current_members');

        // Update status if full
        if ($group->current_members >= $group->max_members) {
            $group->update(['status' => 'full']);
        }

    // Notify User
        try {
            $this->notificationService->sendToUser(
                $userId,
                'Yêu cầu được chấp nhận',
                "Bạn đã được duyệt vào nhóm '{$group->topic}'",
                'group_approved',
                ['group_id' => $groupId]
            );
        } catch (\Exception $e) {
            \Log::error("Failed to notify approveMember: " . $e->getMessage());
        }

        return response()->json(['message' => 'Đã duyệt thành viên.']);
    }

    // Reject Member (Creator Only)
    public function rejectMember(Request $request, $groupId, $userId)
    {
        $group = StudyGroup::findOrFail($groupId);

        if ($group->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $member = \DB::table('study_group_members')
            ->where('study_group_id', $groupId)
            ->where('user_id', $userId)
            ->first();

        if (!$member) {
            return response()->json(['message' => 'Member not found'], 404);
        }

        // Update status to rejected
        \DB::table('study_group_members')
            ->where('id', $member->id)
            ->update(['status' => 'rejected']);

        // Notify User
        try {
            $this->notificationService->sendToUser(
                $userId,
                'Yêu cầu bị từ chối',
                "Yêu cầu tham gia nhóm '{$group->topic}' của bạn đã bị từ chối.",
                'group_rejected',
                ['group_id' => $groupId]
            );
        } catch (\Exception $e) {
             \Log::error("Failed to notify rejectMember: " . $e->getMessage());
        }

        return response()->json(['message' => 'Đã từ chối thành viên.']);
    }

    // Remove Member (Creator Only)
    // Allows creator to remove an approved member from the group
    public function removeMember(Request $request, $groupId, $userId)
    {
        $group = StudyGroup::findOrFail($groupId);

        if ($group->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $member = \DB::table('study_group_members')
            ->where('study_group_id', $groupId)
            ->where('user_id', $userId)
            ->first();

        if (!$member) {
            return response()->json(['message' => 'Member not found'], 404);
        }

        // Delete member
        \DB::table('study_group_members')
            ->where('id', $member->id)
            ->delete();

        // Decrement count if they were approved
        if ($member->status === 'approved') {
            $group->decrement('current_members');
            $group->update(['status' => 'open']);
        }

        // Notify User
        try {
            $this->notificationService->sendToUser(
                $userId,
                'Đã bị xóa khỏi nhóm',
                "Bạn đã bị xóa khỏi nhóm '{$group->topic}' bởi trưởng nhóm.",
                'group_removed',
                ['group_id' => $groupId]
            );
        } catch (\Exception $e) {
            \Log::error("Failed to notify removeMember: " . $e->getMessage());
        }

        return response()->json(['message' => 'Đã xóa thành viên khỏi nhóm.']);
    }

    // Leave Group
    public function leaveGroup(Request $request, $id)
    {
        $user = $request->user();
        $group = StudyGroup::findOrFail($id);

        // Check if user was approved before deleting
        $member = \DB::table('study_group_members')
            ->where('study_group_id', $id)
            ->where('user_id', $user->id)
            ->first();

        if ($member) {
            $wasApproved = $member->status === 'approved';

            \DB::table('study_group_members')->where('id', $member->id)->delete();

            if ($wasApproved) {
                $group->decrement('current_members');
                $group->update(['status' => 'open']);
            }
        }

        return response()->json(['message' => 'Đã rời nhóm.']);
    }

    // Get Members
    public function getGroupMembers($id)
    {
        $members = \DB::table('study_group_members')
            ->join('users', 'study_group_members.user_id', '=', 'users.id')
            ->where('study_group_id', $id)
            ->select('users.id', 'users.name', 'users.phone_number', 'study_group_members.status', 'study_group_members.joined_at')
            ->get();

        return response()->json($members);
    }

    // Get My Study Groups (Groups where user is a member)
    public function myStudyGroups(Request $request)
    {
        $user = $request->user('sanctum');

        if (!$user || !$user->id) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            // Get study groups where user is a member
            $groupIds = \DB::table('study_group_members')
                ->where('user_id', $user->id)
                ->whereIn('status', ['approved', 'pending'])
                ->pluck('study_group_id')
                ->toArray();

            // If user has no groups, return empty array
            if (empty($groupIds)) {
                return response()->json([]);
            }

            // Load groups - don't use with() to avoid relationship errors
            $groups = StudyGroup::whereIn('id', $groupIds)
                ->latest()
                ->get();

            // If no groups found, return empty
            if ($groups->isEmpty()) {
                return response()->json([]);
            }

            // Get membership status
            $memberStatus = \DB::table('study_group_members')
                ->where('user_id', $user->id)
                ->pluck('status', 'study_group_id')
                ->toArray();

            // Map groups to array format
            $result = [];
            foreach ($groups as $group) {
                if (!$group || !$group->id) {
                    continue; // Skip invalid groups
                }

                $data = $group->toArray();

                // Add membership status
                $data['membership_status'] = $memberStatus[$group->id] ?? null;

                // Calculate confirmed members count
                $approvedCount = \DB::table('study_group_members')
                    ->where('study_group_id', $group->id)
                    ->where('status', 'approved')
                    ->count();
                $data['current_members'] = $approvedCount;

                // --- NEW: Add Notification Logic ---
                $data['pending_requests_count'] = 0;
                $data['has_new_messages'] = false; // Placeholder for chat integ

                // Logic: If user is creator, count pending requests
                if ($group->creator_id == $user->id) {
                     $pendingCount = \DB::table('study_group_members')
                        ->where('study_group_id', $group->id)
                        ->where('status', 'pending')
                        ->count();
                     $data['pending_requests_count'] = $pendingCount;
                }
                
                // Logic: Chat Unread (Ideally synced from Firestore/Chat Table)
                // For now, we can mock or use a simple logic if chat table exists
                 $data['has_new_messages'] = false; // TODO: Implement real chat check
                // -----------------------------------

                // Add creator info safely
                if ($group->creator_id) {
                    $creator = \App\Models\User::find($group->creator_id);
                    if ($creator) {
                        $data['creator'] = [
                            'id' => $creator->id,
                            'name' => $creator->name ?? 'Unknown',
                        ];
                    } else {
                        $data['creator'] = null;
                    }
                } else {
                    $data['creator'] = null;
                }

                $result[] = $data;
            }

            return response()->json($result);
        } catch (\Exception $e) {
            \Log::error('Error in myStudyGroups: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json([
                'message' => 'Lỗi khi lấy danh sách nhóm học tập của bạn.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // Join Course (Đăng ký lớp học)
    /// 
    /// **Purpose:**
    /// - Cho phép học viên đăng ký vào lớp học do gia sư tạo
    /// - Kiểm tra xem học viên đã đăng ký chưa
    /// - Kiểm tra số lượng học viên còn trống
    /// 
    /// **Parameters:**
    /// - `$id`: Course ID
    /// 
    /// **Process:**
    /// 1. Tìm course theo ID
    /// 2. Kiểm tra xem user đã đăng ký chưa
    /// 3. Kiểm tra số lượng học viên còn trống
    /// 4. Thêm vào bảng course_students với status 'approved' (tự động duyệt)
    /// 5. Tăng current_students nếu cần
    /// 
    /// **Returns:**
    /// - Success: JSON với message thành công
    /// - Error: JSON với error message và status code
    public function joinCourse(Request $request, $id)
    {
        $user = $request->user('sanctum');

        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $course = Course::findOrFail($id);

        // Kiểm tra xem user đã đăng ký chưa
        $existing = \DB::table('course_students')
            ->where('course_id', $id)
            ->where('user_id', $user->id)
            ->first();

        if ($existing) {
            return response()->json(['message' => 'Bạn đã đăng ký lớp học này rồi.'], 400);
        }

        // Kiểm tra số lượng học viên hiện tại
        $currentStudents = \DB::table('course_students')
            ->where('course_id', $id)
            ->where('status', 'approved')
            ->count();

        // Lấy max_students từ course (nếu có field này)
        // Nếu không có, dùng giá trị mặc định từ migration (10)
        $maxStudents = $course->max_students ?? 10;

        if ($currentStudents >= $maxStudents) {
            return response()->json(['message' => 'Lớp học đã đầy.'], 400);
        }

        // --- TRIAL LOGIC (HỌC THỬ 7 NGÀY TỰ ĐỘNG) ---
        $price = $course->price;
        
        // Luôn cho phép vào lớp trước, nếu có phí thì thiết lập trạng thái học thử
        $paymentStatus = $price > 0 ? 'trial' : 'paid';
        $nextPaymentDue = $price > 0 ? now()->addDays(7) : null;

        \DB::table('course_students')->insert([
            'course_id' => $id,
            'user_id' => $user->id,
            'status' => 'approved',
            'payment_status' => $paymentStatus,
            'next_payment_due' => $nextPaymentDue,
            'enrolled_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $message = $price > 0 
           ? 'Đăng ký lớp học thành công! Bạn có 7 ngày học thử trước khi phải đóng học phí.'
           : 'Đăng ký lớp học thành công!';

        return response()->json(['message' => $message]);
    }

    // Leave Course (Rời lớp học)
    /// 
    /// **Purpose:**
    /// - Cho phép học viên rời khỏi lớp học đã đăng ký
    /// 
    /// **Parameters:**
    /// - `$id`: Course ID
    /// 
    /// **Process:**
    /// 1. Tìm course theo ID
    /// 2. Xóa record trong bảng course_students
    /// 
    /// **Returns:**
    /// - Success: JSON với message thành công
    /// - Error: JSON với error message và status code
    public function leaveCourse(Request $request, $id)
    {
        $user = $request->user('sanctum');

        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Xóa record trong bảng course_students
        $deleted = \DB::table('course_students')
            ->where('course_id', $id)
            ->where('user_id', $user->id)
            ->delete();

        if ($deleted) {
             // --- REFUND LOGIC ---
             $transaction = \App\Models\Transaction::where('reference_id', "course_join_{$id}_{$user->id}")
                ->where('type', 'payment')
                ->first();

             if ($transaction) {
                 $amountToRefund = abs($transaction->amount);
                 $wallet = \App\Models\Wallet::where('id', $transaction->wallet_id)->first();
                 if ($wallet) {
                    $wallet->balance += $amountToRefund;
                    $wallet->save();

                    \App\Models\Transaction::create([
                        'wallet_id' => $wallet->id,
                        'amount' => $amountToRefund,
                        'type' => 'refund',
                        'description' => "Hoàn tiền rời lớp học #{$id}",
                        'reference_id' => "course_leave_{$id}_{$user->id}",
                        'status' => 'success'
                    ]);
                 }
             }

            return response()->json(['message' => 'Đã rời lớp học và hoàn tiền.']);
        } else {
            return response()->json(['message' => 'Bạn chưa đăng ký lớp học này.'], 404);
        }
    }

    // Kick Student from Course (Đuổi học viên & Hoàn tiền)
    public function removeStudentFromCourse(Request $request, $id)
    {
        $user = $request->user('sanctum');
         if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $course = Course::findOrFail($id);

        // Verify Tutor
        if ($course->tutor_id != $user->id && $user->role !== 'admin') { // Allow admin too just in case
             // Check if user maps to tutor
             $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
             if (!$tutor || $course->tutor_id != $tutor->id) {
                 return response()->json(['message' => 'Unauthorized'], 403);
             }
        }

        $studentId = $request->input('student_id');
        $sessionsStudied = $request->input('sessions_studied', 0);
        $totalSessions = $request->input('total_sessions', 10); // Default 10 if not provided
        $reason = $request->input('reason', '');

        if (!$studentId) {
            return response()->json(['message' => 'Student ID required'], 400);
        }

        // Check student existence
        $studentRecord = \DB::table('course_students')
            ->where('course_id', $id)
            ->where('user_id', $studentId)
            ->first();

        if (!$studentRecord) {
             return response()->json(['message' => 'Học viên không tồn tại trong lớp.'], 404);
        }

        // --- REFUND LOGIC ---
        // Find original payment
        $transaction = \App\Models\Transaction::where('reference_id', 'like', "course_join_{$id}_{$studentId}%")
            ->where('type', 'payment')
            ->orderBy('created_at', 'desc')
            ->first();

        $refundAmount = 0;
        $message = "Đã xóa học viên.";

        if ($transaction) {
            $amountPaid = abs($transaction->amount);
            
            // Refund = AmountPaid * (Remaining / Total)
            // Remaining = Total - Studied
            if ($totalSessions > 0) {
                $remainingSessions = max(0, $totalSessions - $sessionsStudied);
                $ratio = $remainingSessions / $totalSessions;
                $refundAmount = $amountPaid * $ratio;
            }

            // Execute Refund
            if ($refundAmount > 0) {
                 $wallet = \App\Models\Wallet::where('id', $transaction->wallet_id)->first();
                 if ($wallet) {
                    $wallet->balance += $refundAmount;
                    $wallet->save();

                    \App\Models\Transaction::create([
                        'wallet_id' => $wallet->id,
                        'amount' => $refundAmount,
                        'type' => 'refund',
                        'description' => "Hoàn tiền bị xóa khỏi lớp: {$course->title} (Học {$sessionsStudied}/{$totalSessions} buổi)",
                        'reference_id' => "course_kick_{$id}_{$studentId}_" . time(),
                        'status' => 'success'
                    ]);
                    $message .= " Đã hoàn lại " . number_format($refundAmount) . "đ ({$sessionsStudied}/{$totalSessions} buổi).";
                 }
            }
        } else {
            $message .= " Không tìm thấy giao dịch thanh toán để hoàn tiền (Có thể là miễn phí hoặc data cũ).";
        }

        // Remove from course
        \DB::table('course_students')
            ->where('id', $studentRecord->id)
            ->delete();

        // Notify Student
        $notificationBody = "Bạn đã bị xóa khỏi lớp '{$course->title}'. $message";
        if (!empty($reason)) {
            $notificationBody .= "\nLý do: $reason";
        }

        try {
            $this->notificationService->sendToUser(
                $studentId,
                'Thông báo từ lớp học',
                $notificationBody,
                'course_removed',
                ['course_id' => $id]
            );
        } catch (\Exception $e) {
            \Log::error("Failed to notify kicked student: " . $e->getMessage());
        }

        return response()->json(['message' => $message]);
    }

    // Get My Courses (Lấy danh sách lớp học của tôi)
    /// 
    /// **Purpose:**
    /// - Lấy danh sách lớp học mà học viên đã đăng ký
    /// - Hoặc lớp học mà gia sư đã tạo
    /// 
    /// **Returns:**
    /// - List of courses với thông tin enrollment status
    public function myCourses(Request $request)
    {
        $user = $request->user('sanctum');

        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            // Lấy course IDs mà user đã đăng ký (với status approved)
            $enrolledCourseIds = \DB::table('course_students')
                ->where('user_id', $user->id)
                ->where('status', 'approved')
                ->pluck('course_id')
                ->toArray();

            // Lấy courses mà user là tutor (nếu user là tutor)
            $tutorCourses = [];
            $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
            if ($tutor) {
                // Ensure we use TUTOR ID, not User ID
                $tutorCourses = Course::where('tutor_id', $tutor->id)->pluck('id')->toArray();
            }

            // Merge cả hai danh sách
            $allCourseIds = array_unique(array_merge($enrolledCourseIds, $tutorCourses));

            if (empty($allCourseIds)) {
                return response()->json([]);
            }

            // Lấy thông tin courses
            $courses = Course::whereIn('id', $allCourseIds)
                ->with('tutor')
                ->latest()
                ->get();

            // Thêm enrollment status và student info cho mỗi course
            $courses = $courses->map(function ($course) use ($user, $enrolledCourseIds, $tutor) {
                $data = $course->toArray();
                $data['is_enrolled'] = in_array($course->id, $enrolledCourseIds);
                // Check if user is the tutor of this course
                $isTutor = ($tutor && $course->tutor_id == $tutor->id);
                $data['is_tutor'] = $isTutor;

                if ($isTutor) {
                    $students = \DB::table('course_students')
                        ->join('users', 'course_students.user_id', '=', 'users.id')
                        ->where('course_students.course_id', $course->id)
                        ->where('course_students.status', 'approved')
                        ->select('users.id', 'users.name', 'users.phone_number', 'users.email', 'course_students.enrolled_at')
                        ->get()
                        ->toArray();
                    $data['students'] = $students;
                    $data['student_count'] = count($students);
                } else {
                    $studentCount = \DB::table('course_students')
                        ->where('course_id', $course->id)
                        ->where('status', 'approved')
                        ->count();
                    $data['student_count'] = $studentCount;
                    $data['students'] = [];
                }

                return $data;
            });

            return response()->json($courses);
        } catch (\Exception $e) {
            \Log::error('Error in myCourses: ' . $e->getMessage());
            return response()->json([
                'message' => 'Lỗi khi lấy danh sách lớp học của bạn.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // --- Announcements ---
    public function indexAnnouncements(Request $request, $courseId)
    {
        $course = Course::findOrFail($courseId);
        return response()->json($course->announcements()->with('user:id,name,avatar_url')->latest()->get());
    }

    public function storeAnnouncement(Request $request, $courseId)
    {
        $user = $request->user('sanctum');
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $course = Course::findOrFail($courseId);
        $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
        $isTutor = ($course->tutor_id == $user->id) || ($tutor && $course->tutor_id == $tutor->id);

        if (!$isTutor) {
             return response()->json(['message' => 'Chỉ giảng viên mới được đăng thông báo.'], 403);
        }

        $validated = $request->validate(['content' => 'required|string']);

        $announcement = $course->announcements()->create([
            'user_id' => $user->id,
            'content' => $validated['content'],
        ]);

        return response()->json($announcement->load('user:id,name,avatar_url'), 201);
    }
}
