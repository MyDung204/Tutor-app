<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use App\Services\FirebaseNotificationService;
use Illuminate\Support\Facades\Hash;

class BookingController extends Controller
{
    protected $notificationService;

    public function __construct(FirebaseNotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json([]);

        // Get all possible IDs that could represent this tutor
        // 1. Correct Tutor ID from 'tutors' table
        $tutorIds = \App\Models\Tutor::where('user_id', $user->id)->pluck('id')->toArray();
        
        // 2. Add the User ID itself (fallback for legacy/bad data)
        $tutorIds[] = $user->id;

        \Log::info("BookingController: Searching for bookings with Tutor IDs: " . implode(', ', $tutorIds));

        // If no tutor profile exists and user is just a student, fallback to student view
        // But if they have ANY bookings as a tutor (even with User ID), show them.
        
        $bookings = Booking::with(['student', 'tutor'])
            ->whereIn('tutor_id', $tutorIds)
            ->latest()
            ->get();

        // If query found something, return it.
        // If not, and they are NOT a tutor in 'tutors' table, return student bookings.
        if ($bookings->isEmpty() && empty(\App\Models\Tutor::where('user_id', $user->id)->first())) {
             \Log::info("BookingController: No Tutor bookings found and not a registered Tutor. Showing Student Bookings for ID {$user->id}.");
             return Booking::with('tutor')
                ->where('student_id', $user->id)
                ->latest()
                ->get();
        }

        \Log::info("Booking Result Count: " . $bookings->count());
        return $bookings;
    }

    public function lockSlot(Request $request)
    {
        // Request: tutor_id, date (Y-m-d), time_slot (HH:mm - HH:mm), price, type, duration_months, days_of_week, learning_mode
        $request->validate([
            'tutor_id' => 'required',
            'date' => 'required', 
            'time_slot' => 'required',
            'price' => 'required',
            'type' => 'nullable|in:single,long_term',
            'payment_pin' => 'nullable|string',
            'grade_level' => 'nullable|string',
            'address' => 'nullable|string' 
        ]);

        // Parse time slot "09:00 - 11:00"
        $times = explode(' - ', $request->time_slot);
        if (count($times) != 2)
            return response()->json(['message' => 'Invalid time slot'], 400);

        $cleanDate = Carbon::parse($request->date)->format('Y-m-d');
        $startTime = Carbon::parse($cleanDate . ' ' . $times[0]);
        $endTime = Carbon::parse($cleanDate . ' ' . $times[1]);

        // Restriction: Booking must be at least 12 hours in advance (was implicit, now verified)
        if ($startTime->lt(now()->addHours(12))) {
             return response()->json(['message' => 'Bạn chỉ có thể đặt lịch học trước 12 tiếng.'], 400);
        }

        // ... (Previous code)
        // Check availability (Basic check for primary slot)
        $exists = Booking::where('tutor_id', $request->tutor_id)
            ->where(function ($q) use ($startTime, $endTime) {
                $q->whereBetween('start_time', [$startTime, $endTime])
                    ->where('status', '!=', 'cancelled');
            })->exists();

        if ($exists) {
            return response()->json(['message' => 'Slot already taken'], 409);
        }

        $studentId = $request->user() ? $request->user()->id : ($request->student_id ?? 1);
        $type = $request->type ?? 'single';
        $learningMode = $request->learning_mode ?? 'online';
        $gradeLevel = $request->grade_level; 
        $address = $request->address;
        
        // --- PAYMENT LOGIC START ---
        $initialPayment = 0;
        $childBookingsData = []; // Store to create later
        $payFull = $request->boolean('pay_full');

        // 1. Calculate Initial Payment
        if ($type == 'single') {
            $initialPayment = $request->price;
        } else if ($type == 'long_term' && $request->has('duration_months')) {
            // Calculate sessions
            $durationMonths = (int)$request->duration_months;
            $targetDays = $request->days_of_week; 
            
            // Add Parent Session to Payment
            $initialPayment += $request->price;

            // Simulate Loop for children to count cost
            $tempDate = Carbon::parse($cleanDate)->addDay();
            $endDate = Carbon::parse($cleanDate)->addMonths($durationMonths);
            $firstMonthEnd = Carbon::parse($cleanDate)->addDays(30);

            while ($tempDate->lte($endDate)) {
                $cDay = $tempDate->dayOfWeek;
                $myDay = ($cDay == 0) ? 8 : $cDay + 1;

                if (in_array($myDay, $targetDays)) {
                    // Logic: If Pay Full, always charge.
                    // If Monthly, charge only if within first 30 days.
                    if ($payFull || $tempDate->lte($firstMonthEnd)) {
                        $initialPayment += $request->price;
                    }
                    // Store for creation
                    $childBookingsData[] = [
                        'start' => Carbon::parse($tempDate->format('Y-m-d') . ' ' . $times[0]),
                        'end' => Carbon::parse($tempDate->format('Y-m-d') . ' ' . $times[1]),
                    ];
                }
                $tempDate->addDay();
            }
        }

        // 2. Check Wallet & Verify PIN
        $wallet = \App\Models\Wallet::firstOrCreate(['user_id' => $studentId]);
        
        // Verify PIN if wallet has one (force check if deducted > 0)
        if ($initialPayment > 0) {
            if (!$request->payment_pin) {
                 return response()->json(['message' => 'Vui lòng nhập mã PIN thanh toán'], 400);   
            }
            if (!$wallet->payment_pin || !\Illuminate\Support\Facades\Hash::check($request->payment_pin, $wallet->payment_pin)) {
                 return response()->json(['message' => 'Mã PIN thanh toán không chính xác'], 400);
            }
        }

        if ($wallet->balance < $initialPayment) {
            return response()->json([
                'message' => 'Số dư không đủ. Cần thanh toán trước: ' . number_format($initialPayment) . 'đ',
                'required_amount' => $initialPayment
            ], 400); 
        }

        DB::beginTransaction();
        try {
            // 3. Create Bookings FIRST (to get ID)
            $booking = Booking::create([
                'tutor_id' => $request->tutor_id,
                'student_id' => $studentId, 
                'start_time' => $startTime,
                'end_time' => $endTime,
                'total_price' => $request->price,
                'status' => 'pending', 
                'notes' => 'Prepaid: ' . $initialPayment,
                'type' => $type,
                'learning_mode' => $learningMode,
                'grade_level' => $gradeLevel,
                'address' => $address
            ]);

            // Create Child Bookings from pre-calculated data
            foreach ($childBookingsData as $childData) {
                 Booking::create([
                    'tutor_id' => $request->tutor_id,
                    'student_id' => $studentId,
                    'start_time' => $childData['start'],
                    'end_time' => $childData['end'],
                    'total_price' => $request->price,
                    'status' => 'pending',
                    'type' => 'single', // Child is single type
                    'parent_id' => $booking->id,
                    'learning_mode' => $learningMode,
                    'grade_level' => $gradeLevel,
                    'address' => $address
                ]);
            }

            // Deduct & Create Transaction
            if ($initialPayment > 0) {
                $wallet->balance -= $initialPayment;
                $wallet->save();

                \App\Models\Transaction::create([
                    'wallet_id' => $wallet->id,
                    'amount' => -$initialPayment,
                    'type' => 'payment',
                'description' => $type == 'long_term' 
                    ? ($payFull ? "Thanh toán trọn gói dài hạn #{$booking->id}" : "Thanh toán tháng đầu cho lịch học định kỳ #{$booking->id}")
                    : "Thanh toán đặt lịch học #{$booking->id}",
                    'reference_id' => "booking_{$booking->id}",
                    'status' => 'success'
                ]);
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Lỗi thanh toán: ' . $e->getMessage()], 500);
        }

        // 3. Auto-send Proposal to Chat (Rest of the code...)

        // 3. Auto-send Proposal to Chat
        $tutorUser = \App\Models\Tutor::find($request->tutor_id)->user_id; // Get Tutor's user_id
        $studentUser = $studentId; // Student's user_id

        $u1 = min($tutorUser, $studentUser);
        $u2 = max($tutorUser, $studentUser);

        $conv = \App\Models\Conversation::where('user1_id', $u1)->where('user2_id', $u2)->first();
        if (!$conv) {
            $conv = \App\Models\Conversation::create(['user1_id' => $u1, 'user2_id' => $u2, 'last_message' => '']);
        }

        // Create Message
        $msgContent = "Đề nghị học mới: " . ($type == 'long_term' ? "Dài hạn" : "Một buổi") . " vào " . $startTime->format('H:i d/m/Y');
        \App\Models\Message::create([
            'conversation_id' => $conv->id,
            'sender_id' => $studentUser,
            'content' => $msgContent,
            'is_read' => false,
            'type' => 'booking_request',
            'booking_id' => $booking->id
        ]);

        $conv->update(['last_message' => '[Đề nghị học] ' . $msgContent, 'updated_at' => now()]);

        // Notify Tutor about new booking request
        $tutor = \App\Models\Tutor::find($request->tutor_id);
        if ($tutor) {
            $this->notificationService->sendToUser(
                $tutor->user_id,
                'Yêu cầu đặt lịch mới',
                "Bạn có yêu cầu đặt lịch mới vào " . $startTime->format('H:i d/m/Y') . ($type == 'long_term' ? " (Đăng kí dài hạn)" : ""),
                'booking',
                ['booking_id' => $booking->id]
            );
        }

        return response()->json($booking->load(['tutor', 'children']), 201);
    }

    public function confirm($id)
    {
        $booking = Booking::findOrFail($id);
        
        // Use Transaction to ensure all child bookings are updated too
        DB::transaction(function() use ($booking) {
            $booking->update(['status' => 'confirmed']); // Mapped to 'Upcoming'
            
            // If it's a long-term booking, confirm all pending children
            if ($booking->type == 'long_term') {
                Booking::where('parent_id', $booking->id)
                    ->where('status', 'pending')
                    ->update(['status' => 'confirmed']);
            }
        });

        // Notify Student
        $this->notificationService->sendToUser(
            $booking->student_id,
            'Đặt lịch thành công ✅',
            "Buổi học của bạn lúc " . Carbon::parse($booking->start_time)->format('H:i d/m/Y') . " đã được xác nhận.",
            'booking',
            ['booking_id' => $booking->id]
        );

        return response()->json(['success' => true]);
    }

    public function reject($id)
    {
        $booking = Booking::findOrFail($id);
        
        // Only Tutor should be able to reject from this endpoint (or check ownership)
        // For simplicity, we assume auth middleware handles tutor check
        
        DB::transaction(function() use ($booking) {
            $booking->update(['status' => 'cancelled']);
            
            // If it's a long-term booking, cancel all children
            if ($booking->type == 'long_term') {
                Booking::where('parent_id', $booking->id)
                    ->where('status', 'pending')
                    ->update(['status' => 'cancelled']);
            }

            // --- REFUND LOGIC ---
            // Find payment transaction
            $transaction = \App\Models\Transaction::where('reference_id', "booking_{$booking->id}")
                ->where('type', 'payment')
                ->first();

            if ($transaction) {
               $amountToRefund = abs($transaction->amount);
               $wallet = \App\Models\Wallet::where('id', $transaction->wallet_id)->first();
               if ($wallet) {
                  $wallet->balance += $amountToRefund;
                  $wallet->save();

                  \App\Models\Transaction::create([
                      'wallet_id' => $wallet->id,
                      'amount' => $amountToRefund,
                      'type' => 'refund',
                      'description' => "Hoàn tiền do gia sư từ chối lịch #{$booking->id}",
                      'reference_id' => "refund_{$booking->id}",
                      'status' => 'success'
                  ]);
               }
            }
        });

        // Notify Student
        $this->notificationService->sendToUser(
            $booking->student_id,
            'Yêu cầu bị từ chối ❌',
            "Gia sư không thể nhận lớp vào " . Carbon::parse($booking->start_time)->format('H:i d/m/Y'),
            'booking',
            ['booking_id' => $booking->id]
        );

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
        
        // --- REFUND LOGIC ---
        // New Policy: Refund if cancelled >= 12h before start time
        $startTime = Carbon::parse($booking->start_time);
        $shouldRefund = $startTime->gt(now()->addHours(12));

        if ($shouldRefund) {
             $transaction = \App\Models\Transaction::where('reference_id', "booking_{$booking->id}")
                ->where('type', 'payment')
                ->first();

             if ($transaction) {
                 $amountToRefund = abs($transaction->amount);
                 $wallet = \App\Models\Wallet::where('id', $transaction->wallet_id)->first();
                 if ($wallet) {
                    $wallet->balance += $amountToRefund;
                    $wallet->save();

                    \App\Models\Transaction::create([
                        'wallet_id' => $wallet->id,
                        'amount' => $amountToRefund,
                        'type' => 'refund',
                        'description' => "Hoàn tiền hủy lịch #{$booking->id} (Hủy trước 12h)",
                        'reference_id' => "refund_{$booking->id}",
                        'status' => 'success'
                    ]);
                 }
             }
        }

        // Notify Tutor if student cancels
        $tutor = $booking->tutor;
        if ($tutor) {
            $this->notificationService->sendToUser(
                $tutor->user_id,
                'Lịch học bị hủy ❌',
                "Học viên đã hủy buổi học lúc " . Carbon::parse($booking->start_time)->format('H:i d/m/Y'),
                'booking',
                ['booking_id' => $booking->id]
            );
        }

        return response()->json(['success' => true]);
    }

    public function updateSessionInfo(Request $request, $id)
    {
        $booking = Booking::findOrFail($id);

        // Verification: Current user must be the tutor of this booking
        $tutor = \App\Models\Tutor::where('user_id', $request->user()->id)->first();
        if (!$tutor || $booking->tutor_id != $tutor->id) {
             return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'lesson_topic' => 'nullable|string|max:255',
            'tutor_feedback' => 'nullable|string',
            'status' => 'nullable|in:completed',
            'meeting_link' => 'nullable|string'
        ]);

        $updateData = [];
        if ($request->has('lesson_topic')) $updateData['lesson_topic'] = $request->lesson_topic;
        if ($request->has('tutor_feedback')) $updateData['tutor_feedback'] = $request->tutor_feedback;

        if ($request->has('meeting_link')) {
             $updateData['meeting_link'] = $request->meeting_link;
        }

        if ($request->has('status') && $request->status == 'completed') {
            $updateData['status'] = 'completed';
        }

        $booking->update($updateData);

        // Notify Student if meeting link is added
        if ($request->has('meeting_link') && $request->meeting_link) {
             $this->notificationService->sendToUser(
                $booking->student_id,
                'Lớp học đã bắt đầu 🔴',
                "Gia sư đã mở phòng học. Hãy vào lớp ngay!",
                'booking',
                ['booking_id' => $booking->id]
            );
        }

        return response()->json($booking);
    }
}
