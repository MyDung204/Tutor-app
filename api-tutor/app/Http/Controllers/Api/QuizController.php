<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Quiz;
use App\Models\QuizAttempt;
use App\Models\QuizOption;
use App\Models\QuizQuestion;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class QuizController extends Controller
{
    // List quizzes (Tutor sees their own, Student sees published ones)
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'tutor') {
            // Tutor: list my quizzes
            $quizzes = Quiz::where('tutor_id', $user->id)
                ->withCount('questions')
                ->latest()
                ->get();
        } else {
            // Student: list published quizzes
            // Optional: filter by tutor_id if provided
            $query = Quiz::where('is_published', true)->with('tutor');

            if ($request->has('tutor_id')) {
                $query->where('tutor_id', $request->tutor_id);
            }

            $quizzes = $query->latest()->get();
        }

        return response()->json($quizzes);
    }

    // Get quiz details
    public function show($id, Request $request)
    {
        $user = $request->user();
        $quiz = Quiz::with(['tutor'])->withCount('questions')->findOrFail($id);

        if ($user->role === 'student' && !$quiz->is_published) {
            return response()->json(['message' => 'Quiz not found or not published'], 404);
        }

        // Load questions. For students, hide 'is_correct' in options.
        if ($user->role === 'tutor' && $quiz->tutor_id === $user->id) {
            $quiz->load(['questions.options']);
        } else {
            // Student view: Load questions and options but hide is_correct
            $quiz->load(['questions' => function ($q) {
                $q->with(['options' => function ($o) {
                    $o->select(['id', 'quiz_question_id', 'content']); // Exclude is_correct
                }]);
            }]);
        }

        return response()->json($quiz);
    }

    // Create a new quiz (Tutor only)
    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'tutor') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Validate
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'time_limit_minutes' => 'nullable|integer',
            'is_published' => 'boolean',
            'questions' => 'required|array|min:1',
            'questions.*.content' => 'required|string',
            'questions.*.points' => 'required|integer|min:1',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.options.*.content' => 'required|string',
            'questions.*.options.*.is_correct' => 'required|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            DB::beginTransaction();

            // Create Quiz
            $quiz = Quiz::create([
                'tutor_id' => $user->id,
                'title' => $request->title,
                'description' => $request->description,
                'time_limit_minutes' => $request->time_limit_minutes,
                'is_published' => $request->is_published ?? false,
            ]);

            // Create Questions & Options
            foreach ($request->questions as $qData) {
                $question = $quiz->questions()->create([
                    'content' => $qData['content'],
                    'points' => $qData['points'] ?? 1,
                ]);

                foreach ($qData['options'] as $oData) {
                    $question->options()->create([
                        'content' => $oData['content'],
                        'is_correct' => $oData['is_correct'],
                    ]);
                }
            }

            DB::commit();
            return response()->json($quiz->load('questions.options'), 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to create quiz: ' . $e->getMessage()], 500);
        }
    }

    // Submit quiz answers (Student)
    public function submit($id, Request $request)
    {
        $user = $request->user();
        $quiz = Quiz::findOrFail($id);

        // Validate
        $request->validate([
            'answers' => 'required|array', // [{'question_id': 1, 'option_id': 2}]
            'answers.*.question_id' => 'required|integer|exists:quiz_questions,id',
            'answers.*.option_id' => 'required|integer|exists:quiz_options,id',
        ]);

        $score = 0;
        $totalPoints = 0;
        $correctAnswers = [];

        // Load all questions with correct options for grading
        $questions = $quiz->questions()->with('options')->get();

        foreach ($questions as $question) {
            $totalPoints += $question->points;
            
            // Find student's answer for this question
            $studentAnswer = collect($request->answers)->firstWhere('question_id', $question->id);
            
            // Logic for grading
            // Assuming single choice for now: if option_id matches a correct option
            if ($studentAnswer) {
                $selectedOptionId = $studentAnswer['option_id'];
                $correctOption = $question->options->where('is_correct', true)->first();
                
                if ($correctOption && $correctOption->id == $selectedOptionId) {
                    $score += $question->points;
                }
                
                // Add to review data
                $correctAnswers[$question->id] = $correctOption ? $correctOption->id : null;
            }
        }

        // Record attempt
        $attempt = QuizAttempt::create([
            'user_id' => $user->id,
            'quiz_id' => $quiz->id,
            'score' => $score,
            'started_at' => now(), // Ideally passed from frontend or tracked earlier
            'completed_at' => now(),
        ]);

        return response()->json([
            'score' => $score,
            'total_points' => $totalPoints,
            'attempt_id' => $attempt->id,
            'correct_answers' => $correctAnswers, // Map of question_id -> correct_option_id
        ]);
    }

    // Get attempts history
    public function attempts(Request $request)
    {
        $user = $request->user();
        $attempts = QuizAttempt::where('user_id', $user->id)
            ->with('quiz')
            ->latest()
            ->get();
            
        return response()->json($attempts);
    }
}
