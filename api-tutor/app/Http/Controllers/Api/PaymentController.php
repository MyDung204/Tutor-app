<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    /**
     * Webhook to receive payment notification from SePay/Casso (Simulated)
     */
    public function webhook(Request $request)
    {
        // 1. Validate incoming data
        // Assuming SePay/Casso standard format or a simplified Sandbox format
        // Expected payload: { "id": "12345", "amount": 50000, "content": "NAP 101", "gateway": "VietQR" }
        $request->validate([
            'id' => 'required|string', // Unique Payment ID from Bank
            'amount' => 'required|numeric|min:0',
            'content' => 'required|string',
        ]);

        $transactionId = $request->input('id');
        $amount = $request->input('amount');
        $content = $request->input('content');

        Log::info("Payment Webhook Received: ID=$transactionId, Amount=$amount, Content=$content");

        // 2. Parse User ID from Content (Regex)
        // Pattern: "NAP 123" or "NAP123" or "nap 123"
        if (!preg_match('/NAP\s*(\d+)/i', $content, $matches)) {
            return response()->json(['success' => false, 'message' => 'Invalid content format. User ID not found.'], 400);
        }

        $userId = $matches[1];

        // 3. Find User & Wallet
        $user = User::find($userId);
        if (!$user) {
            return response()->json(['success' => false, 'message' => 'User not found.'], 404);
        }

        // 4. Idempotency Check
        // Check if this transaction ID has already been processed
        $existing = Transaction::where('reference_id', $transactionId)->first();
        if ($existing) {
            return response()->json(['success' => true, 'message' => 'Transaction already processed.'], 200);
        }

        // 5. Process Payment (Atomic)
        DB::beginTransaction();
        try {
            // Ensure Wallet Exists
            $wallet = Wallet::firstOrCreate(
                ['user_id' => $user->id],
                ['balance' => 0, 'currency' => 'VND']
            );

            // Update Balance
            $wallet->increment('balance', $amount);

            // Record Transaction
            Transaction::create([
                'wallet_id' => $wallet->id,
                'amount' => $amount,
                'type' => 'deposit',
                'description' => "Nạp tiền qua VietQR: $content",
                'reference_id' => $transactionId,
                'status' => 'success',
            ]);

            DB::commit();

            // Optional: Send Notification to User
            // \App\Models\AppNotification::create(...)

            return response()->json(['success' => true, 'message' => 'Payment processed successfully.'], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Payment Processing Error: " . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Internal Server Error'], 500);
        }
    }

    /**
     * Simulate Payment for Sandbox/Dev (Called from App)
     */
    public function simulate(Request $request)
    {
        // This endpoint mimics the Bank sending a webhook
        // Input: user_id, amount
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:1000'
        ]);

        $userId = $request->user_id;
        $amount = $request->amount;
        
        // Generate a fake bank transaction ID
        $fakeRefId = 'FT' . time() . rand(1000, 9999);
        $content = "NAP $userId";

        // Create a new internal request to call the webhook logic (or just reuse logic)
        // Reusing logic via internal call is cleaner or just instantiating Request
        
        $payload = [
            'id' => $fakeRefId,
            'amount' => $amount,
            'content' => $content,
        ];

        // Call webhook directly
        $webhookRequest = Request::create('/api/payment/webhook', 'POST', $payload);
        // We can just call the method directly if we want, but let's do a full dispatch or just copy logic.
        // Actually, let's just create a new Request object and pass it to webhook().
        
        return $this->webhook($webhookRequest);
    }
}
