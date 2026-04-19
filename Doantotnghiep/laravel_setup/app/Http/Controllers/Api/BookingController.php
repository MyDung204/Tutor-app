<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class BookingController extends Controller
{
    public function index(Request $request)
    {
        // Return bookings for current user
        return Booking::with('tutor')
            ->where('student_id', $request->user()->id)
            ->latest()
            ->get();
    }

    public function lockSlot(Request $request)
    {
        // Request: tutor_id, date (Y-m-d), time_slot (HH:mm - HH:mm), price
        $request->validate([
            'tutor_id' => 'required',
            'date' => 'required|date',
            'time_slot' => 'required',
            'price' => 'required'
        ]);

        // Parse time slot
        // "09:00 - 11:00"
        $times = explode(' - ', $request->time_slot);
        if (count($times) != 2)
            return response()->json(['message' => 'Invalid time slot'], 400);

        $startTime = Carbon::parse($request->date . ' ' . $times[0]);
        $endTime = Carbon::parse($request->date . ' ' . $times[1]);

        // Check availability
        $exists = Booking::where('tutor_id', $request->tutor_id)
            ->where(function ($q) use ($startTime, $endTime) {
                $q->whereBetween('start_time', [$startTime, $endTime])
                    ->where('status', '!=', 'cancelled');
            })->exists();

        if ($exists) {
            return response()->json(['message' => 'Slot already taken'], 409);
        }

        $booking = Booking::create([
            'tutor_id' => $request->tutor_id,
            'student_id' => $request->user()->id,
            'start_time' => $startTime,
            'end_time' => $endTime,
            'total_price' => $request->price,
            'status' => 'pending', // Mapped to 'Locked' for frontend
            'notes' => ''
        ]);

        return response()->json($booking->load('tutor'), 201);
    }

    public function confirm($id)
    {
        $booking = Booking::findOrFail($id);
        $booking->update(['status' => 'confirmed']); // Mapped to 'Upcoming'
        return response()->json(['success' => true]);
    }

    public function cancel($id)
    {
        $booking = Booking::findOrFail($id);
        // Add check policy if needed (user owns booking)
        if ($booking->student_id != auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        $booking->update(['status' => 'cancelled']);
        return response()->json(['success' => true]);
    }
}
