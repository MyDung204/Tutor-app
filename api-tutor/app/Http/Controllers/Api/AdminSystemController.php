<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Subject;

class AdminSystemController extends Controller
{
    // GET: List all subjects
    public function subjects()
    {
        $subjects = Subject::orderBy('name')->get();
        return response()->json($subjects);
    }

    // POST: Create a new subject
    public function storeSubject(Request $request)
    {
        $request->validate([
            'name' => 'required|string|unique:subjects',
            'description' => 'nullable|string',
            'is_active' => 'boolean'
        ]);

        $subject = Subject::create($request->all());
        return response()->json($subject, 201);
    }

    // PUT: Update a subject
    public function updateSubject(Request $request, $id)
    {
        $subject = Subject::findOrFail($id);

        $request->validate([
            'name' => 'required|string|unique:subjects,name,' . $subject->id,
            'description' => 'nullable|string',
            'is_active' => 'boolean'
        ]);

        $subject->update($request->all());
        return response()->json($subject);
    }

    // DELETE: Delete a subject
    public function destroySubject($id)
    {
        $subject = Subject::findOrFail($id);
        $subject->delete();
        return response()->json(['message' => 'Subject deleted successfully']);
    }
}
