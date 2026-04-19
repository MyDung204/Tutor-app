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

        // 2. Search
        if ($request->has('search') && $request->search != null) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('subjects', 'like', "%{$search}%");
            });
        }

        // 3. Filters
        if ($request->has('min_price'))
            $query->where('hourly_rate', '>=', $request->min_price);
        if ($request->has('max_price'))
            $query->where('hourly_rate', '<=', $request->max_price);
        if ($request->has('location'))
            $query->where('location', 'like', "%{$request->location}%");

        return $query->get();
    }

    public function show($id)
    {
        return Tutor::find($id);
    }
}
