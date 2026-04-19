<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tutor;
use App\Models\TutorRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class SmartMatchingController extends Controller
{
    // 1. Student finds Tutors for a specific Request
    public function matchTutorsForRequest($requestId)
    {
        $request = TutorRequest::findOrFail($requestId);
        
        // Ensure the authenticated user owns this request
        if ($request->student_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Matching Logic
        $tutors = Tutor::query()->get()->filter(function ($tutor) use ($request) {
            $score = 0;
            
            // 1. Subject Match (Critical)
            // Tutor subjects is an array e.g. ["Math", "Physics"]
            // Request subject is string e.g. "Math Grade 10"
            $subjectMatch = false;
            foreach ($tutor->subjects ?? [] as $subj) {
                if (stripos($request->subject, $subj) !== false || stripos($subj, $request->subject) !== false) {
                    $subjectMatch = true;
                    break;
                }
            }
            if (!$subjectMatch) return false; // Must match subject
            $score += 50;

            // 2. Budget Match
            // Tutor hourly_rate vs Request max_budget
            // Allow 20% slack
            if ($tutor->hourly_rate <= $request->max_budget * 1.2) {
                $score += 30;
                // Bonus for being under min_budget (cheap)
                if ($tutor->hourly_rate <= $request->min_budget) {
                    $score += 10;
                }
            } else {
                return false; // Too expensive
            }

            // 3. Mode Match
            // Request mode: 'Online', 'Offline', 'Any'
            // Tutor mode: ['Online', 'Offline']
            if ($request->mode !== 'Any') {
                if (!in_array($request->mode, $tutor->teaching_mode ?? [])) {
                    return false;
                }
            }
            $score += 10;

            // 4. Location Match (Only if Offline)
            if ($request->mode === 'Offline' || $request->mode === 'Any') {
                if ($request->mode === 'Offline' && stripos($tutor->location, $request->location) === false && stripos($request->location, $tutor->location) === false) {
                    // Reduce score or filter? Let's just reduce score for now, maybe they travel.
                    // But usually location is hard constraint for Offline.
                    // Let's filter if mode is Strictly Offline.
                    if ($request->mode === 'Offline') return false; 
                } else {
                    $score += 10;
                }
            }

            // 5. Rating Bonus
            $score += ($tutor->rating * 2);

            $tutor->match_score = $score;
            return true;
        });

        // Sort by score
        $sortedTutors = $tutors->sortByDesc('match_score')->values();

        return response()->json($sortedTutors);
    }

    // 2. Tutor finds Requests suitable for them
    public function matchRequestsForTutor(Request $request)
    {
        $user = Auth::user();
        if (!$user || !$user->tutor) {
            return response()->json(['message' => 'Tutor profile not found'], 404);
        }

        $tutor = $user->tutor;

        $requests = TutorRequest::where('status', 'open')->get()->filter(function ($req) use ($tutor) {
            $score = 0;

            // 1. Subject Match
            $subjectMatch = false;
            foreach ($tutor->subjects ?? [] as $subj) {
                if (stripos($req->subject, $subj) !== false || stripos($subj, $req->subject) !== false) {
                    $subjectMatch = true;
                    break;
                }
            }
            if (!$subjectMatch) return false;
            $score += 40;

            // 2. Budget Match
            // Request Max Budget >= Tutor Rate
            if ($req->max_budget >= $tutor->hourly_rate * 0.9) { // 10% tolerance lower
                 $score += 30;
            } else {
                return false;
            }

            // 3. Location/Mode
            if ($req->mode === 'Offline') {
                if (!in_array('Offline', $tutor->teaching_mode ?? [])) return false;
                // Check location
                if (stripos($tutor->location, $req->location) === false && stripos($req->location, $tutor->location) === false) {
                     return false; // Assuming strict location for tutors for now
                }
            } else if ($req->mode === 'Online') {
                if (!in_array('Online', $tutor->teaching_mode ?? [])) return false;
            }

            $req->match_score = $score;
            return true;
        });

        $sortedRequests = $requests->sortByDesc('match_score')->values();
        
        // Load student info
        $sortedRequests->load('student');

        return response()->json($sortedRequests);
    }
}
