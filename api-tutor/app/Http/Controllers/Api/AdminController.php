<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Tutor;

class AdminController extends Controller
{
    /**
     * Get list of users (students and tutors) for admin management.
     */
    public function users(Request $request)
    {
        // Basic search
        $query = User::query();

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->has('role')) {
            $query->where('role', $request->role);
        }
        
        if ($request->has('view_banned')) {
             $query->where('is_banned', true);
        }

        // Pagination
        $users = $query->orderBy('created_at', 'desc')->paginate(100);

        return response()->json($users);
    }

    public function showUser($id)
    {
        try {
            $user = User::with(['tutorProfile', 'wallet'])->findOrFail($id);
            
            // Basic Stats
            $stats = [
                'report_count' => \App\Models\Report::where('target_id', $id)->count(),
                'booking_count' => \App\Models\Booking::where('student_id', $id)->count(),
            ];
    
            if ($user->role === 'tutor') {
                 // Add Tutor specific stats
                 $stats['class_count'] = \App\Models\Course::where('tutor_id', $user->tutorProfile?->id)->count();
            }
    
            // Recent Activity (Mixed)
            $recentActivity = []; // TODO: Implement activity feed if needed, or just let frontend fetch specific lists
    
            // Load recent transactions
            if ($user->wallet) {
                $user->wallet->setRelation('transactions', 
                    $user->wallet->transactions()->latest()->limit(20)->get()
                );
            }
    
            return response()->json([
                'user' => $user,
                'stats' => $stats,
                'wallet' => $user->wallet, // Contains transactions
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Error showing user details: ' . $e->getMessage());
            \Illuminate\Support\Facades\Log::error($e->getTraceAsString());
            return response()->json(['message' => 'Server Error'], 500);
        }
    }

    public function updateUser($id, Request $request)
    {
        $user = User::find($id);
        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'phone_number' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            // Add other fields as needed
        ]);

        $user->update($validated);

        return response()->json(['message' => 'User updated successfully', 'user' => $user]);
    }

    /**
     * Get system statistics (Revenue, Users, etc.)
     * Mock implementation for now, or connect to real counts if tables exist.
     */
    public function stats()
    {
        // Connect to real counts
        $totalUsers = User::count();
        $totalTutors = Tutor::count();
        // Note: Tutor model is separate from User role 'tutor' in current seeders, need to be careful.
        // Assuming Tutor model rows are what we display as "Tutors" in the app.

        // Mock revenue for now as we don't have a transaction history table fully seeded with amounts
        $totalRevenue = 15000000;

        return response()->json([
            'total_revenue' => $totalRevenue,
            'total_users' => $totalUsers,
            'total_tutors' => $totalTutors,
            'pending_tutors' => 5, // Mock pending
            'activities' => [
                [
                    'id' => 1,
                    'title' => 'Đăng ký mới',
                    'body' => 'Học viên Nguyễn Văn A vừa đăng ký.',
                    'time_ago' => '5 phút trước'
                ],
                [
                    'id' => 2,
                    'title' => 'Giao dịch',
                    'body' => 'Gia sư Trần Thị B vừa nhận thanh toán.',
                    'time_ago' => '10 phút trước'
                ]
            ]
        ]);
    }

    /**
     * Toggle ban status of a user.
     */
    public function tutorRequests()
    {
        return response()->json(Tutor::where('is_verified', false)->orWhere('is_verified', 0)->orderBy('created_at', 'desc')->get());
    }

    public function approveTutor($id)
    {
        $tutor = Tutor::find($id);
        if ($tutor) {
            $tutor->is_verified = true;
            $tutor->save();
            return response()->json(['message' => 'Tutor approved']);
        }
        return response()->json(['message' => 'Tutor not found'], 404);
    }

    public function rejectTutor($id)
    {
        $tutor = Tutor::find($id);
        if ($tutor) {
            $tutor->delete();
            return response()->json(['message' => 'Tutor rejected']);
        }
        return response()->json(['message' => 'Tutor not found'], 404);
    }

    public function toggleBan($id)
    {
        $user = User::find($id);
        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        $user->is_banned = !$user->is_banned;
        $user->save();

        $status = $user->is_banned ? 'banned' : 'active';
        return response()->json(['message' => "User has been {$status}", 'is_banned' => $user->is_banned]);
    }
    public function reports(Request $request)
    {
        $query = \App\Models\Report::query();
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        return response()->json($query->orderBy('created_at', 'desc')->get());
    }

    public function resolveReport($id, Request $request)
    {
        $report = \App\Models\Report::find($id);
        if ($report) {
            $report->status = $request->input('status', 'resolved');
            $report->save();
            return response()->json(['message' => 'Report updated', 'report' => $report]);
        }
        return response()->json(['message' => 'Report not found'], 404);
    }
    public function getAuditLogs(Request $request)
    {
        $type = $request->input('type', 'alert'); // 'alert' or 'scan_log'
        return response()->json(
            \App\Models\AuditLog::where('type', $type)
                ->orderBy('created_at', 'desc')
                ->limit(20)
                ->get()
        );
    }

    // --- Course Approval ---
    public function pendingCourses()
    {
        return response()->json(\App\Models\Course::with('tutor')->where('status', 'pending')->latest()->get());
    }

    public function approveCourse($id)
    {
        $course = \App\Models\Course::findOrFail($id);
        $course->update(['status' => 'open']);
        
        // Notify Tutor
        // (Assuming NotificationService is injected or used statically if setup)
        return response()->json(['message' => 'Course approved']);
    }

    public function rejectCourse($id)
    {
        $course = \App\Models\Course::findOrFail($id);
        $course->update(['status' => 'rejected']);
        return response()->json(['message' => 'Course rejected']);
    }

    public function getUserActivities($id)
    {
        try {
            $user = User::with('wallet')->findOrFail($id);
            $activities = collect([]);

            // 1. Bookings
            $bookings = \App\Models\Booking::where('student_id', $id)
                ->orWhere('tutor_id', $user->tutorProfile?->id ?? 0)
                ->latest()
                ->take(20)
                ->get();

            foreach ($bookings as $booking) {
                $activities->push([
                    'type' => 'booking',
                    'title' => 'Lịch học: ' . $booking->app_status,
                    'description' => "Thời gian: " . $booking->time_slot . " (" . $booking->date . ")",
                    'created_at' => $booking->created_at,
                    'data' => $booking // Optional: include full object if needed
                ]);
            }

            // 2. Transactions
            if ($user->wallet) {
                $transactions = $user->wallet->transactions()->latest()->take(20)->get();
                foreach ($transactions as $tx) {
                    $activities->push([
                        'type' => 'transaction',
                        'title' => 'Giao dịch: ' . $tx->type,
                        'description' => number_format($tx->amount) . ' ' . $tx->currency . ' - ' . $tx->description,
                        'created_at' => $tx->created_at,
                        'data' => $tx
                    ]);
                }
            }

            // 3. Reports (as target)
            $reports = \App\Models\Report::where('target_id', $id)->latest()->take(10)->get();
            foreach ($reports as $report) {
                $activities->push([
                    'type' => 'report',
                    'title' => 'Bị tố cáo: ' . $report->reason,
                    'description' => $report->description,
                    'created_at' => $report->created_at,
                    'data' => $report
                ]);
            }

            // Sort by date desc
            $sortedActivities = $activities->sortByDesc('created_at')->values()->take(50);

            return response()->json($sortedActivities);

        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Error fetching activities: ' . $e->getMessage());
            return response()->json(['message' => 'Server Error'], 500);
        }
    }

    /**
     * Broadcast a notification to users
     */
    public function broadcast(Request $request, \App\Services\FirebaseNotificationService $service)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'target_role' => 'required|string|in:all,tutor,student',
        ]);

        $query = User::query();

        if ($request->target_role !== 'all') {
            $query->where('role', $request->target_role);
        }

        // Get users with device tokens
        $users = $query->whereNotNull('device_token')->get();

        $successCount = 0;
        foreach ($users as $user) {
            try {
                $service->sendToUser(
                    $user->id,
                    $request->title,
                    $request->body,
                    'system_broadcast'
                );
                $successCount++;
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::warning("Failed to push notification to User ID {$user->id}");
            }
        }

        return response()->json([
            'message' => 'Broadcast completed',
            'total_sent' => $successCount,
            'target_group' => $request->target_role
        ]);
    }
}
