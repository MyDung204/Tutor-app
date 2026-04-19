<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\StudyGroup;
use App\Models\Course;
use Illuminate\Http\Request;

class SharedLearningController extends Controller
{
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

            $groups = $groups->map(function ($group) use ($memberStatus) {
                $data = $group->toArray();
                $data['membership_status'] = $memberStatus[$group->id] ?? null;
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
        
        // Lấy danh sách courses
        $courses = Course::with('tutor')->where('status', '!=', 'closed')->latest()->get();
        
        // Nếu user đã đăng nhập, thêm enrollment status
        if ($user) {
            // Lấy danh sách course IDs mà user đã đăng ký
            $enrolledCourseIds = \DB::table('course_students')
                ->where('user_id', $user->id)
                ->where('status', 'approved')
                ->pluck('course_id')
                ->toArray();
            
            // Map courses để thêm enrollment status và students list
            $courses = $courses->map(function ($course) use ($user, $enrolledCourseIds) {
                $data = $course->toArray();
                
                // Thêm enrollment status
                $data['is_enrolled'] = in_array($course->id, $enrolledCourseIds);
                
                // Nếu user là tutor của course, thêm danh sách học viên
                if ($course->tutor_id == $user->id) {
                    $students = \DB::table('course_students')
                        ->join('users', 'course_students.user_id', '=', 'users.id')
                        ->where('course_students.course_id', $course->id)
                        ->where('course_students.status', 'approved')
                        ->select('users.id', 'users.name', 'users.phone_number', 'course_students.enrolled_at')
                        ->get()
                        ->toArray();
                    
                    $data['students'] = $students;
                } else {
                    // Nếu không phải tutor, chỉ trả về số lượng học viên
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
            // Nếu chưa đăng nhập, chỉ thêm student count
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

        return response()->json(['message' => 'Đã duyệt thành viên.']);
    }

    // Reject Member (Creator Only)
    /// 
    /// **Purpose:**
    /// - Rejects a pending member request
    /// - Only group creator can reject members
    /// 
    /// **Parameters:**
    /// - `$groupId`: Study group ID
    /// - `$userId`: User ID to reject
    /// 
    /// **Process:**
    /// 1. Validates creator permission
    /// 2. Finds member in database
    /// 3. Updates status to 'rejected'
    /// 
    /// **Returns:**
    /// - Success: JSON with success message
    /// - Error: JSON with error message and status code
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

        return response()->json(['message' => 'Đã từ chối thành viên.']);
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
                ->where('status', 'approved')
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

        // Thêm học viên vào lớp học với status 'approved' (tự động duyệt)
        \DB::table('course_students')->insert([
            'course_id' => $id,
            'user_id' => $user->id,
            'status' => 'approved',
            'enrolled_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'Đăng ký lớp học thành công!']);
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
            return response()->json(['message' => 'Đã rời lớp học.']);
        } else {
            return response()->json(['message' => 'Bạn chưa đăng ký lớp học này.'], 404);
        }
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
            $tutorCourses = Course::where('tutor_id', $user->id)->pluck('id')->toArray();

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

            // Thêm enrollment status cho mỗi course
            $courses = $courses->map(function ($course) use ($user, $enrolledCourseIds) {
                $data = $course->toArray();
                $data['is_enrolled'] = in_array($course->id, $enrolledCourseIds);
                $data['is_tutor'] = $course->tutor_id == $user->id;
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

    // Create Course (Tạo lớp học)
    /// 
    /// **Purpose:**
    /// - Cho phép gia sư tạo lớp học mới (1-1 hoặc nhóm)
    /// 
    /// **Parameters:**
    /// - `title`: Tên lớp học (required)
    /// - `subject`: Môn học (required)
    /// - `grade_level`: Cấp độ (required)
    /// - `description`: Mô tả chi tiết (required)
    /// - `price`: Học phí (required)
    /// - `max_students`: Số lượng tối đa (required, default: 1 cho 1-1, 5 cho nhóm)
    /// - `schedule`: Lịch học (required)
    /// - `mode`: Hình thức Online/Offline (required)
    /// - `address`: Địa điểm học (required nếu Offline)
    /// - `start_date`: Ngày bắt đầu (required)
    /// 
    /// **Process:**
    /// 1. Validate input
    /// 2. Lấy tutor_id từ user hiện tại
    /// 3. Tạo course mới
    /// 4. Trả về course đã tạo
    /// 
    /// **Returns:**
    /// - Success: JSON với course object
    /// - Error: JSON với error message và status code
    public function storeCourse(Request $request)
    {
        $user = $request->user('sanctum');
        
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Tìm tutor_id từ user_id
        $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
        
        if (!$tutor) {
            return response()->json(['message' => 'Bạn chưa đăng ký làm gia sư.'], 403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'subject' => 'required|string',
            'grade_level' => 'required|string',
            'description' => 'required|string',
            'price' => 'required|numeric|min:0',
            'max_students' => 'required|integer|min:1',
            'schedule' => 'required|string',
            'mode' => 'required|in:Online,Offline',
            'address' => 'required_if:mode,Offline|string|nullable',
            'start_date' => 'required|date',
        ]);

        try {
            $course = Course::create([
                'tutor_id' => $tutor->id,
                'title' => $validated['title'],
                'subject' => $validated['subject'],
                'grade_level' => $validated['grade_level'],
                'description' => $validated['description'],
                'price' => $validated['price'],
                'max_students' => $validated['max_students'],
                'schedule' => $validated['schedule'],
                'mode' => $validated['mode'],
                'address' => $validated['address'] ?? null,
                'start_date' => $validated['start_date'],
                'status' => 'open',
            ]);

            // Load tutor relationship và format response
            $course->load('tutor');
            
            // Format response để frontend dễ parse
            $response = $course->toArray();
            $response['tutor'] = [
                'id' => $course->tutor->id ?? null,
                'name' => $course->tutor->name ?? 'Giảng viên',
            ];
            $response['is_enrolled'] = false; // Mới tạo nên chưa có ai đăng ký
            $response['students'] = [];

            return response()->json($response, 201);
        } catch (\Exception $e) {
            \Log::error('Error creating course: ' . $e->getMessage());
            return response()->json([
                'message' => 'Lỗi khi tạo lớp học.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // Update Course (Cập nhật lớp học)
    /// 
    /// **Purpose:**
    /// - Cho phép gia sư cập nhật thông tin lớp học đã tạo
    /// - Chỉ tutor tạo lớp mới có quyền cập nhật
    /// 
    /// **Parameters:**
    /// - `$id`: Course ID
    /// - Các field giống như storeCourse (optional)
    /// 
    /// **Process:**
    /// 1. Tìm course theo ID
    /// 2. Kiểm tra quyền (chỉ tutor tạo lớp mới được cập nhật)
    /// 3. Validate input
    /// 4. Cập nhật course
    /// 5. Trả về course đã cập nhật
    /// 
    /// **Returns:**
    /// - Success: JSON với course object
    /// - Error: JSON với error message và status code
    public function updateCourse(Request $request, $id)
    {
        $user = $request->user('sanctum');
        
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $course = Course::findOrFail($id);
        
        // Tìm tutor_id từ user_id
        $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
        
        if (!$tutor || $course->tutor_id != $tutor->id) {
            return response()->json(['message' => 'Bạn không có quyền cập nhật lớp học này.'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'subject' => 'sometimes|string',
            'grade_level' => 'sometimes|string',
            'description' => 'sometimes|string',
            'price' => 'sometimes|numeric|min:0',
            'max_students' => 'sometimes|integer|min:1',
            'schedule' => 'sometimes|string',
            'mode' => 'sometimes|in:Online,Offline',
            'address' => 'required_if:mode,Offline|string|nullable',
            'start_date' => 'sometimes|date',
        ]);

        try {
            $course->update($validated);
            $course->load('tutor');

            return response()->json($course);
        } catch (\Exception $e) {
            \Log::error('Error updating course: ' . $e->getMessage());
            return response()->json([
                'message' => 'Lỗi khi cập nhật lớp học.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // Delete Course (Xóa lớp học)
    /// 
    /// **Purpose:**
    /// - Cho phép gia sư xóa lớp học đã tạo
    /// - Chỉ tutor tạo lớp mới có quyền xóa
    /// 
    /// **Parameters:**
    /// - `$id`: Course ID
    /// 
    /// **Returns:**
    /// - Success: JSON với success message
    /// - Error: JSON với error message và status code
    public function destroyCourse(Request $request, $id)
    {
        $user = $request->user('sanctum');
        
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $course = Course::findOrFail($id);
        
        // Tìm tutor_id từ user_id
        $tutor = \App\Models\Tutor::where('user_id', $user->id)->first();
        
        if (!$tutor || $course->tutor_id != $tutor->id) {
            return response()->json(['message' => 'Bạn không có quyền xóa lớp học này.'], 403);
        }

        try {
            // Xóa tất cả enrollments trước
            \DB::table('course_students')->where('course_id', $id)->delete();
            
            // Xóa course
            $course->delete();

            return response()->json(['message' => 'Đã xóa lớp học thành công.']);
        } catch (\Exception $e) {
            \Log::error('Error deleting course: ' . $e->getMessage());
            return response()->json([
                'message' => 'Lỗi khi xóa lớp học.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
