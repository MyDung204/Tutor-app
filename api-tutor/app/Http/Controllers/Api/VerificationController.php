<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VerificationRequest;
use App\Models\Tutor;
use Illuminate\Http\Request;

class VerificationController extends Controller
{
    // Submit KYC Request (Tutor Only)
    public function submit(Request $request)
    {
        $user = $request->user();
        
        // 1. Check Role
        if ($user->role !== 'tutor') {
            return response()->json(['message' => 'Tính năng này chỉ dành cho Gia sư.'], 403);
        }

        // 2. Check existing pending request
        $existing = VerificationRequest::where('user_id', $user->id)
            ->where('status', 'pending')
            ->first();
        if ($existing) {
            return response()->json(['message' => 'Bạn đang có yêu cầu chờ duyệt.'], 400);
        }

        $request->validate([
            'front_image_url' => 'required|string', // URL from upload service
            'back_image_url' => 'required|string',
        ]);

        $verification = VerificationRequest::create([
            'user_id' => $user->id,
            'type' => 'tutor_card', // Fixed type for now
            'front_image_url' => $request->front_image_url,
            'back_image_url' => $request->back_image_url,
            'status' => 'pending',
        ]);

        return response()->json($verification, 201);
    }

    // Get Status
    public function getStatus(Request $request)
    {
        $latest = VerificationRequest::where('user_id', $request->user()->id)
            ->latest()
            ->first();
            
        return response()->json($latest);
    }

    // Admin: Approve
    public function approve($id)
    {
        // Add Admin Middleware check in routes
        $req = VerificationRequest::findOrFail($id);
        
        if ($req->status !== 'pending') {
            return response()->json(['message' => 'Request is not pending'], 400);
        }

        $req->update(['status' => 'approved']);

        // Update User/Tutor Verification Status
        $req->user->update(['identity_verified_at' => now()]);
        
        $tutor = Tutor::where('user_id', $req->user_id)->first();
        if ($tutor) {
            $tutor->update(['is_verified' => true]);
        }

        return response()->json(['message' => 'Approved successfully']);
    }

    // Admin: Reject
    public function reject(Request $request, $id)
    {
        // Add Admin Middleware check
        $req = VerificationRequest::findOrFail($id);
        
        $req->update([
            'status' => 'rejected',
            'note' => $request->note ?? 'Hồ sơ không hợp lệ.'
        ]);

        return response()->json(['message' => 'Rejected successfully']);
    }
    
    // Admin: List Pending
    public function listPending()
    {
        return VerificationRequest::with('user')->where('status', 'pending')->get();
    }
}
