<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class MapController extends Controller
{
    /**
     * Update current user's location
     */
    public function updateLocation(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'is_incognito' => 'nullable|boolean',
        ]);

        $user = auth()->user();
        if (!$user) {
             return response()->json(['message' => 'Unauthorized'], 401);
        }

        $data = [
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
        ];

        if ($request->has('is_incognito')) {
            $data['is_incognito'] = $request->is_incognito;
        }

        $user->update($data);

        return response()->json(['message' => 'Location updated successfully']);
    }

    /**
     * Get nearby users
     */
    public function getNearbyUsers(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius' => 'nullable|numeric|min:0', // in km
            'role' => 'nullable|string', // 'tutor' or 'student'
            
            // Filters
            'min_price' => 'nullable|numeric',
            'max_price' => 'nullable|numeric',
            'subject' => 'nullable|string',
        ]);

        $lat = $request->latitude;
        $lng = $request->longitude;
        $radius = $request->radius ?? 10;
        $role = $request->role; 

        // Haversine formula
        $query = User::select(
            'users.*',
            DB::raw("(6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) * cos(radians(users.longitude) - radians(?)) + sin(radians(?)) * sin(radians(users.latitude)))) AS distance")
        )
        ->addBinding([$lat, $lng, $lat], 'select');

        // Filter by role
        if ($role) {
            $query->where('role', $role);
        }

        // Advanced Filters (Only for searching Tutors)
        if ($role === 'tutor') {
            $query->whereHas('tutorProfile', function ($q) use ($request) {
                if ($request->has('min_price')) {
                    $q->where('hourly_rate', '>=', $request->min_price);
                }
                if ($request->has('max_price')) {
                    $q->where('hourly_rate', '<=', $request->max_price);
                }
                if ($request->has('subject')) {
                    // Assuming subjects is JSON or text. If JSON: JSON_CONTAINS or LIKE
                    $q->where('subjects', 'LIKE', '%' . $request->subject . '%');
                }
            });
            $query->with('tutorProfile');
        }

        // Exclude self
        if (auth()->check()) {
            $query->where('id', '!=', auth()->id());
        }

        // Apply radius and order
        $results = $query->having('distance', '<', $radius)
                         ->orderBy('distance')
                         ->take(50) 
                         ->get();

        // Process results: Always fuzz location for privacy (relative location only)
        $results->transform(function ($user) {
            // Fuzz location: Random offset between -0.005 and 0.005 (~500m)
            $fuzzLat = (rand(-50, 50) / 10000.0);
            $fuzzLng = (rand(-50, 50) / 10000.0);

            $user->latitude += $fuzzLat;
            $user->longitude += $fuzzLng;
            
            return $user;
        });

        return response()->json($results);
    }
}
