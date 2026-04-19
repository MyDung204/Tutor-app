<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Tutor;
use Illuminate\Http\Request;

class TutorController extends Controller
{
    public function index(Request $request)
    {
        $query = Tutor::query()->with('user.badges');

        // 1. Featured
        if ($request->has('featured') && $request->featured == 1) {
            return $query->where('rating', '>=', 4.5)->limit(5)->get();
        }

        // 2. Text Search (Name or Subjects)
        if ($request->has('search') && $request->search != null) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('subjects', 'like', "%{$search}%");
            });
        }

        // 3. Filter by Subject (Exact or Like)
        if ($request->has('subjects') && $request->subjects != null) {
            $subjects = explode(',', $request->subjects);
            $query->where(function ($q) use ($subjects) {
                foreach ($subjects as $subject) {
                    // Robust JSON Search: Match "Subject" inside JSON
                    $q->orWhere('subjects', 'like', '%"' . $subject . '"%');
                    // Fallback: standard like for non-json or partial matches
                    $q->orWhere('subjects', 'like', "%{$subject}%");
                }
            });
        }

        // 4. Filter by Price
        if ($request->has('min_price')) {
            $query->where('hourly_rate', '>=', $request->min_price);
        }
        if ($request->has('max_price')) {
            $query->where('hourly_rate', '<=', $request->max_price);
        }

        // 5. Filter by Teaching Mode (JSON)
        if ($request->has('mode')) {
            $modes = explode(',', $request->mode);
            $query->where(function ($q) use ($modes) {
                foreach ($modes as $mode) {
                    $q->orWhere('teaching_mode', 'like', "%{$mode}%");
                }
            });
        }

        // 6. Gender
        if ($request->has('gender') && $request->gender != 'Bất kỳ') {
            $query->where('gender', $request->gender);
        }

        // 7. Location
        if ($request->has('location')) {
            $query->where('location', 'like', "%{$request->location}%");
        }

        // 8. Min Rating
        if ($request->has('min_rating') && $request->min_rating != null) {
            $query->where('rating', '>=', $request->min_rating);
        }

        // 9. Degrees (Tier or Degree text)
        if ($request->has('degrees') && $request->degrees != null) {
            $degrees = explode(',', $request->degrees);
            $query->where(function ($q) use ($degrees) {
                foreach ($degrees as $degree) {
                    if ($degree == 'Sinh viên') {
                        $q->orWhere('tier', 'student');
                    } elseif ($degree == 'Giáo viên') {
                        $q->orWhere('tier', 'teacher')
                          ->orWhere('degree', 'like', '%Giáo viên%');
                    } else {
                        // Thạc sĩ, Giảng viên, etc.
                        $q->orWhere('degree', 'like', "%{$degree}%");
                    }
                }
            });
        }

        $tutors = $query->get();

        if ($user = $request->user('sanctum')) {
            $favoriteTutorIds = \DB::table('user_favorite_tutors')
                ->where('user_id', $user->id)
                ->pluck('tutor_id')
                ->toArray();
                
            $tutors = $tutors->map(function ($tutor) use ($favoriteTutorIds) {
                $data = $tutor->toArray();
                $data['is_favorite'] = in_array($tutor->id, $favoriteTutorIds);
                return $data;
            });
            return $tutors;
        }

        return $tutors;
    }
    public function show(Request $request, $id)
    {
        $tutorQuery = Tutor::with('user.badges');
        $tutor = $tutorQuery->find($id);
        
        if (!$tutor) {
            return response()->json(['message' => 'Tutor not found'], 404);
        }

        $data = $tutor->toArray();
        $data['is_favorite'] = false;

        if ($user = $request->user('sanctum')) {
            $isFav = \DB::table('user_favorite_tutors')
                ->where('user_id', $user->id)
                ->where('tutor_id', $id)
                ->exists();
            $data['is_favorite'] = $isFav;
        }

        return response()->json($data);
    }

    public function getAvailability(Request $request, $id)
    {
        $tutor = Tutor::findOrFail($id);
        return response()->json($tutor->availabilities);
    }

    public function updateAvailability(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $tutor = Tutor::where('user_id', $user->id)->first();
        if (!$tutor) return response()->json(['message' => 'Tutor profile not found'], 404);

        $request->validate([
            'availabilities' => 'present|array',
            'availabilities.*.day_of_week' => 'required|integer|between:2,8',
            'availabilities.*.start_time' => 'required',
            'availabilities.*.end_time' => 'required',
        ]);

        // Replace existing availabilities
        $tutor->availabilities()->delete();

        $scheduleForJson = [];

        foreach ($request->availabilities as $slot) {
            $tutor->availabilities()->create([
                'day_of_week' => $slot['day_of_week'],
                'start_time' => $slot['start_time'],
                'end_time' => $slot['end_time'],
                'is_recurring' => true 
            ]);

            // Build JSON structure: {'2': ['08:00 - 10:00'], ...}
            $day = (string)$slot['day_of_week'];
            // Normalize time string (08:00:00 -> 08:00) if needed, but input is usually clean. 
            // Better to ensure it's H:i format.
            $start = substr($slot['start_time'], 0, 5);
            $end = substr($slot['end_time'], 0, 5);
            $timeSlot = "$start - $end";

            if (!isset($scheduleForJson[$day])) {
                $scheduleForJson[$day] = [];
            }
            $scheduleForJson[$day][] = $timeSlot;
        }

        // Sync to weekly_schedule column for Frontend consumption
        $tutor->weekly_schedule = $scheduleForJson;
        $tutor->save();

        return response()->json(['message' => 'Availability updated', 'availabilities' => $tutor->availabilities]);
    }
    public function getMyAvailability(Request $request) {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $tutor = Tutor::where('user_id', $user->id)->first();
        if (!$tutor) return response()->json(['message' => 'Tutor profile not found'], 404);

        return response()->json($tutor->availabilities);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $tutor = Tutor::where('user_id', $user->id)->firstOrFail();

        $validated = $request->validate([
            'bio' => 'nullable|string',
            'hourly_rate' => 'nullable|numeric',
            'subjects' => 'nullable|array',
            'location' => 'nullable|string',
            'teaching_mode' => 'nullable|array',
            'university' => 'nullable|string',
            'degree' => 'nullable|string',
            'phone' => 'nullable|string',
        ]);

        $tutor->update($validated);

        return response()->json(['message' => 'Profile updated successfully', 'tutor' => $tutor]);
    }

    public function uploadMaterial(Request $request)
    {
        $user = $request->user();
        // Placeholder for material upload logic
        // In a real app, we would store the file in storage and create a record in a materials table
        return response()->json([
            'message' => 'Material uploaded successfully (Mock)',
            'file_name' => $request->file('material')?->getClientOriginalName() ?? 'unknown.pdf',
            'uploaded_at' => now()->toDateTimeString(),
        ]);
    }

    // --- FAVORITES (WISHLIST) ---
    public function toggleFavorite(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $tutor = Tutor::find($id);
        if (!$tutor) return response()->json(['message' => 'Tutor not found'], 404);

        $existing = \DB::table('user_favorite_tutors')
            ->where('user_id', $user->id)
            ->where('tutor_id', $id)
            ->first();

        if ($existing) {
            \DB::table('user_favorite_tutors')->where('id', $existing->id)->delete();
            return response()->json(['message' => 'Đã bỏ yêu thích', 'is_favorite' => false]);
        } else {
            \DB::table('user_favorite_tutors')->insert([
                'user_id' => $user->id,
                'tutor_id' => $id,
                'created_at' => now(),
                'updated_at' => now()
            ]);
            return response()->json(['message' => 'Đã thêm vào danh sách yêu thích', 'is_favorite' => true]);
        }
    }

    public function getFavorites(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $favoriteTutorIds = \DB::table('user_favorite_tutors')
            ->where('user_id', $user->id)
            ->pluck('tutor_id')
            ->toArray();

        if (empty($favoriteTutorIds)) {
            return response()->json([]);
        }

        $tutors = Tutor::with('user.badges')->whereIn('id', $favoriteTutorIds)->get();
        
        $tutors = $tutors->map(function ($tutor) {
            $data = $tutor->toArray();
            $data['is_favorite'] = true;
            return $data;
        });

        return response()->json($tutors);
    }

    public function myStatistics(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $tutor = Tutor::where('user_id', $user->id)->first();
        if (!$tutor) return response()->json(['message' => 'Tutor not found'], 404);

        $totalRevenue = \DB::table('bookings')
            ->where('tutor_id', $tutor->id)
            ->where('status', 'completed')
            ->sum('total_price');

        $activeClasses = \DB::table('bookings')
            ->where('tutor_id', $tutor->id)
            ->whereIn('status', ['upcoming', 'confirmed'])
            ->count();

        $totalStudents = \DB::table('bookings')
            ->where('tutor_id', $tutor->id)
            ->whereIn('status', ['completed', 'upcoming', 'confirmed'])
            ->distinct('user_id')
            ->count('user_id');

        $completedSessions = \DB::table('bookings')
            ->where('tutor_id', $tutor->id)
            ->where('status', 'completed')
            ->count();

        return response()->json([
            'total_revenue' => $totalRevenue,
            'active_classes' => $activeClasses,
            'total_students' => $totalStudents,
            'teaching_hours' => $completedSessions * 1.5, // Giả định mỗi buổi 1.5h
            'rating' => $tutor->rating,
            'review_count' => $tutor->review_count,
            'completion_rate' => 95,
            'response_time' => '15p'
        ]);
    }

    public function myTuitions(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $tutor = Tutor::where('user_id', $user->id)->first();
        if (!$tutor) return response()->json(['message' => 'Tutor not found'], 404);

        $bookings = \App\Models\Booking::with(['student'])
            ->where('tutor_id', $tutor->id)
            ->orderBy('date', 'desc')
            ->get();

        return response()->json($bookings);
    }
}
