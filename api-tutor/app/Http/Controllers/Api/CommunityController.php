<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Question;
use App\Models\Answer;

class CommunityController extends Controller
{
    /**
     * List questions with pagination.
     */
    public function index(Request $request)
    {
        $questions = Question::with(['user', 'answers.user'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json($questions);
    }

    /**
     * Store a new question.
     */
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'tags' => 'array',
        ]);

        $question = Question::create([
            'user_id' => $request->user()->id,
            'title' => $request->input('title'),
            'content' => $request->input('content'),
            'tags' => $request->input('tags', []),
        ]);

        // Future: Trigger AI Answer Job
        // GenerateAIAnswerJob::dispatch($question);

        return response()->json($question, 201);
    }

    /**
     * Show a single question.
     */
    public function show($id)
    {
        $question = Question::with(['user', 'answers.user'])
            ->findOrFail($id);
            
        // Increment view count
        $question->increment('views');

        return response()->json($question);
    }

    /**
     * Post an answer.
     */
    public function storeAnswer(Request $request, $id)
    {
        $request->validate([
            'content' => 'required|string',
        ]);

        $question = Question::findOrFail($id);

        $answer = $question->answers()->create([
            'user_id' => $request->user()->id,
            'content' => $request->input('content'),
            'is_ai_generated' => false,
        ]);

        return response()->json($answer, 201);
    }
}
