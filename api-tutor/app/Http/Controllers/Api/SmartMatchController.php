<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Tutor;

class SmartMatchController extends Controller
{
    /**
     * Get smart matches for a user based on tags.
     */
    public function getMatches(Request $request)
    {
        $user = $request->user();
        $userTags = $request->input('tags', $user->learning_tags ?? []);

        // If no tags provided, return popular tutors
        if (empty($userTags)) {
            $tutors = Tutor::with('user')
                ->orderBy('review_count', 'desc')
                ->take(10)
                ->get();
            return response()->json([
                'data' => $tutors,
                'message' => 'No tags provided, showing popular tutors.'
            ]);
        }

        // Logic: Calculate overlap score
        // 1. Fetch all tutors
        $tutors = Tutor::with('user')->get();

        $scoredTutors = $tutors->map(function ($tutor) use ($userTags) {
            $tutorTags = $tutor->teaching_tags ?? [];
            $score = 0;

            // Strict Match
            $intersection = array_intersect($userTags, $tutorTags);
            $score += count($intersection) * 10;

            // Partial Match (Subject) - Placeholder logic
            // if (in_array($tutor->main_subject, $userTags)) $score += 5;

            $tutor->match_score = $score;
            return $tutor;
        });

        // 2. Sort by score
        $sortedTutors = $scoredTutors->sortByDesc('match_score')->values()->take(20);

        return response()->json([
            'data' => $sortedTutors,
            'meta' => [
                'tags_used' => $userTags
            ]
        ]);
    }

    /**
     * Save user learning tags.
     */
    public function saveTags(Request $request)
    {
        $request->validate([
            'tags' => 'required|array',
            'tags.*' => 'string'
        ]);

        $user = $request->user();
        $user->learning_tags = $request->tags;
        $user->save();

        return response()->json(['message' => 'Learning profile updated.', 'tags' => $user->learning_tags]);
    }
}
