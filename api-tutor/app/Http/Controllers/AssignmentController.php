<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    public function index(Request $request, $courseId)
    {
        $user = $request->user();
        $assignments = \App\Models\Assignment::where('course_id', $courseId)
            ->withCount('submissions')
            ->orderBy('created_at', 'desc')
            ->get();

        // If user is student, check submission status
        if ($user->role === 'student') {
            $assignments->each(function ($assignment) use ($user) {
                $submission = $assignment->submissions()->where('student_id', $user->id)->first();
                $assignment->is_submitted = $submission ? true : false;
                $assignment->my_submission = $submission;
            });
        }

        return response()->json($assignments);
    }

    public function store(Request $request)
    {
        $request->validate([
            'course_id' => 'required|exists:courses,id',
            'title' => 'required|string',
            'description' => 'nullable|string',
            'due_date' => 'nullable|date',
            'attachment_url' => 'nullable|string',
        ]);

        // Authorization check could be here (ensure user is tutor of course)
        // For now relying on middleware and frontend checks

        $assignment = \App\Models\Assignment::create($request->all());

        return response()->json($assignment, 201);
    }

    public function submit(Request $request, $id)
    {
        $request->validate([
            'content' => 'nullable|string',
            'file_url' => 'nullable|string',
        ]);

        if (!$request->content && !$request->file_url) {
            return response()->json(['message' => 'Nội dung hoặc file không được để trống'], 422);
        }

        $user = $request->user();
        
        // Check if already submitted? Usually allow re-submit or update
        // Using updateOrCreate for simplicity
        $submission = \App\Models\AssignmentSubmission::updateOrCreate(
            ['assignment_id' => $id, 'student_id' => $user->id],
            [
                'content' => $request->content,
                'file_url' => $request->file_url,
                'submitted_at' => now(),
            ]
        );

        return response()->json($submission);
    }

    public function submissions($id)
    {
        // Tutor view: Get all submissions
        $submissions = \App\Models\AssignmentSubmission::where('assignment_id', $id)
            ->with('student:id,name,avatar_url')
            ->orderBy('submitted_at', 'desc')
            ->get();
            
        return response()->json($submissions);
    }

    public function destroy($id)
    {
        $assignment = \App\Models\Assignment::find($id);
        if (!$assignment) {
            return response()->json(['message' => 'Not found'], 404);
        }
        $assignment->delete();
        return response()->json(['message' => 'Deleted']);
    }
}
