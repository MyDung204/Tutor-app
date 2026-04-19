<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TutorRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TutorRequestController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'subject' => 'required|string',
            'grade_level' => 'required|string',
            'description' => 'required|string',
            'min_budget' => 'required|numeric',
            'max_budget' => 'required|numeric',
            'schedule' => 'nullable|string',
            'location' => 'nullable|string',
        ]);

        $tutorRequest = TutorRequest::create([
            'student_id' => $request->user()->id,
            'subject' => $request->subject,
            'grade_level' => $request->grade_level,
            'description' => $request->description,
            'min_budget' => $request->min_budget,
            'max_budget' => $request->max_budget,
            'schedule' => $request->schedule,
            'location' => $request->location,
            'status' => 'open',
            'mode' => 'Any',
        ]);

        return response()->json(['message' => 'Created successfully', 'data' => $tutorRequest], 201);
    }

    public function index(Request $request)
    {
        // For Tutor Dashboard to see requests
        return response()->json(TutorRequest::with('student')->orderBy('created_at', 'desc')->get());
    }

    public function myRequests(Request $request)
    {
        // For Student to see their own requests
        return response()->json(TutorRequest::where('student_id', $request->user()->id)->orderBy('created_at', 'desc')->get());
    }

    public function destroy(Request $request, $id)
    {
        $tutorRequest = TutorRequest::findOrFail($id);

        if ($tutorRequest->student_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $tutorRequest->delete();

        return response()->json(['message' => 'Deleted successfully']);
    }
}
