<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Question;
use App\Models\Answer;
use Illuminate\Http\Request;

class QuestionController extends Controller
{
    public function index()
    {
        // Return latest questions with answers
        return Question::with('answers')->latest()->get();
    }

    public function store(Request $request)
    {
        // Simple Create
        $question = Question::create($request->all());
        return response()->json($question, 201);
    }

    public function storeAnswer(Request $request, $id)
    {
        $request->merge(['question_id' => $id]);
        $answer = Answer::create($request->all());

        // Inc answer count
        $q = Question::find($id);
        $q->increment('answer_count');

        return response()->json($answer, 201);
    }
}
