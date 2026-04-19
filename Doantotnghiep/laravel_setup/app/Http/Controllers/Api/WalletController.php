<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    // Get wallet and transactions
    public function index(Request $request)
    {
        $user = $request->user();
        $wallet = Wallet::firstOrCreate(['user_id' => $user->id]);

        $transactions = Transaction::where('wallet_id', $wallet->id)
            ->latest()
            ->get();

        return response()->json([
            'balance' => $wallet->balance,
            'currency' => $wallet->currency,
            'transactions' => $transactions
        ]);
    }

    // Mock Deposit
    public function deposit(Request $request)
    {
        $request->validate(['amount' => 'required|numeric|min:10000']);
        $user = $request->user();
        $wallet = Wallet::firstOrCreate(['user_id' => $user->id]);

        $wallet->balance += $request->amount;
        $wallet->save();

        Transaction::create([
            'wallet_id' => $wallet->id,
            'amount' => $request->amount,
            'type' => 'deposit',
            'description' => 'Nạp tiền vào ví',
            'status' => 'success'
        ]);

        return response()->json(['success' => true, 'balance' => $wallet->balance]);
    }
}
