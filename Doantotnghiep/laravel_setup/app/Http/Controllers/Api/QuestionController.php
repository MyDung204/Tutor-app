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
        return Question::with('answers')->latest()->get();
    }
    public function store(Request $request)
    {
        $question = Question::create($request->all());
        return response()->json($question, 201);
    }
    public function storeAnswer(Request $request, $id)
    {
        $request->merge(['question_id' => $id]);
        $answer = Answer::create($request->all());
        Question::find($id)->increment('answer_count');
        return response()->json($answer, 201);
    }
}
