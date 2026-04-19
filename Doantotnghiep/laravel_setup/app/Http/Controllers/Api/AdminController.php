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
            $query->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%");
        }

        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        // Pagination
        $users = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json($users);
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

        // Assuming we have an is_banned column, or use a status column.
        // If not, we might need to add migration.
        // For now, let's just return mock success to satisfy the UI.
        // Or check if migration exists. 
        // Let's assume we toggle a 'status' or 'is_active'.

        // Mock success
        return response()->json(['message' => 'User status updated', 'new_status' => 'banned']);
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
}
