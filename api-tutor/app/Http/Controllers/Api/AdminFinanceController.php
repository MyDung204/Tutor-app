<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\WithdrawalRequest;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;

class AdminFinanceController extends Controller
{
    /**
     * List withdrawal requests.
     */
    public function index(Request $request)
    {
        $status = $request->query('status', 'pending');
        
        $requests = WithdrawalRequest::with('user')
            ->where('status', $status)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($requests);
    }

    /**
     * Approve a withdrawal request.
     * Assumes funds were deducted (held) upon request creation.
     */
    public function approve($id)
    {
        $request = WithdrawalRequest::findOrFail($id);

        if ($request->status !== 'pending') {
            return response()->json(['message' => 'Request is not pending'], 400);
        }

        $request->status = 'approved';
        $request->save();

        // Optional: Send notification to user
        // NotificationService::send(...)

        return response()->json(['message' => 'Withdrawal approved']);
    }

    /**
     * Reject a withdrawal request.
     * Refunds the held amount back to the user's wallet.
     */
    public function reject($id, Request $request)
    {
        $withdrawal = WithdrawalRequest::findOrFail($id);

        if ($withdrawal->status !== 'pending') {
            return response()->json(['message' => 'Request is not pending'], 400);
        }

        $request->validate(['reason' => 'required|string']);

        DB::transaction(function () use ($withdrawal, $request) {
            // 1. Update status
            $withdrawal->status = 'rejected';
            $withdrawal->admin_note = $request->reason;
            $withdrawal->save();

            // 2. Refund the wallet
            $wallet = Wallet::where('user_id', $withdrawal->user_id)->first();
            if ($wallet) {
                $wallet->balance += $withdrawal->amount;
                $wallet->save();

                // 3. Log Refund Transaction
                Transaction::create([
                    'wallet_id' => $wallet->id,
                    'amount' => $withdrawal->amount,
                    'type' => 'refund',
                    'description' => 'Hoàn tiền rút: ' . $request->reason,
                    'status' => 'success',
                ]);
            }
        });

        return response()->json(['message' => 'Withdrawal rejected and refunded']);
    }
}
