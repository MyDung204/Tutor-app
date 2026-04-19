<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;
use Carbon\Carbon;

class BookingController extends Controller
{
    public function index(Request $request)
    {
        // Usually filter by user_id
        return Booking::latest()->get();
    }

    public function lockSlot(Request $request)
    {
        // Logic: Check if slot exists
        $exists = Booking::where('tutor_id', $request->tutor_id)
            ->where('date', $request->date)
            ->where('time_slot', $request->time_slot)
            ->where(function ($q) {
                $q->where('status', 'Upcoming')
                    ->orWhere(function ($sub) {
                        $sub->where('status', 'Locked')
                            ->where('locked_until', '>', Carbon::now());
                    });
            })
            ->exists();

        if ($exists) {
            return response()->json(['message' => 'Slot already taken'], 409);
        }

        // Create Lock
        $booking = Booking::create([
            'tutor_id' => $request->tutor_id,
            'user_id' => 'current_user', // Replace with Auth::id() later
            'date' => $request->date,
            'time_slot' => $request->time_slot,
            'price' => $request->price,
            'status' => 'Locked',
            'locked_until' => Carbon::now()->addMinutes(10),
        ]);

        return response()->json($booking, 201);
    }

    public function confirm($id)
    {
        $booking = Booking::find($id);
        $booking->update(['status' => 'Upcoming', 'locked_until' => null]);
        return response()->json($booking);
    }

    public function cancel($id)
    {
        $booking = Booking::find($id);
        $booking->update(['status' => 'Cancelled']);
        return response()->json($booking);
    }
}
