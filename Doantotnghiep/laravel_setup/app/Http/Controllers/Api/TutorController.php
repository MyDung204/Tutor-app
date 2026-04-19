<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Tutor;
use Illuminate\Http\Request;

class TutorController extends Controller
{
    public function index(Request $request)
    {
        $query = Tutor::query();

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

        return $query->get();
    }
    public function show($id)
    {
        return Tutor::find($id);
    }
}
