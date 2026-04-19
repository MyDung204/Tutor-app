<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class WalletController extends Controller
{
    // Get wallet and transactions
    public function index(Request $request)
    {
        $user = $request->user();
        $wallet = Wallet::firstOrCreate(['user_id' => $user->id]);
        
        // Ensure transactions are loaded
        $transactions = Transaction::where('wallet_id', $wallet->id)->latest()->get();

        return response()->json([
            'id' => $wallet->id,
            'balance' => $wallet->balance,
            'currency' => $wallet->currency ?? 'VND', // fallback
            'has_payment_pin' => !is_null($wallet->payment_pin),
            'transactions' => $transactions
        ]);
    }

    // --- PIN SYSTEM ---

    // 1. Setup PIN (Only if null)
    public function setupPin(Request $request)
    {
        $request->validate([
            'pin' => 'required|digits:6|confirmed' // confirmed ensures pin_confirmation matches
        ]);

        $wallet = Wallet::where('user_id', $request->user()->id)->firstOrFail();
        
        if ($wallet->payment_pin) {
            return response()->json(['message' => 'Mã PIN đã được thiết lập. Vui lòng dùng chức năng đổi PIN.'], 400);
        }

        $wallet->payment_pin = Hash::make($request->pin);
        $wallet->save();

        return response()->json(['message' => 'Thiết lập mã PIN thành công']);
    }

    // 2. Change PIN
    public function changePin(Request $request)
    {
        $request->validate([
            'old_pin' => 'required|digits:6',
            'new_pin' => 'required|digits:6|confirmed'
        ]);

        $wallet = Wallet::where('user_id', $request->user()->id)->firstOrFail();

        // Verify Old PIN
        if (!$wallet->payment_pin || !Hash::check($request->old_pin, $wallet->payment_pin)) {
             return response()->json(['message' => 'Mã PIN cũ không chính xác'], 400);
        }

        $wallet->payment_pin = Hash::make($request->new_pin);
        $wallet->save();

        return response()->json(['message' => 'Đổi mã PIN thành công']);
    }

    // 3. Verify PIN (Internal or API check)
    public function verifyPin(Request $request)
    {
        $request->validate(['pin' => 'required|digits:6']);
        
        $wallet = Wallet::where('user_id', $request->user()->id)->first();
        if (!$wallet || !$wallet->payment_pin) {
             return response()->json(['message' => 'Chưa thiết lập mã PIN'], 400);
        }

        if (!Hash::check($request->pin, $wallet->payment_pin)) {
             return response()->json(['message' => 'Sai mã PIN'], 400);
        }

        return response()->json(['valid' => true]);
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

    // Real Withdrawal Request
    public function withdraw(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:50000',
            'bank_name' => 'required|string',
            'account_number' => 'required|string',
            'account_name' => 'required|string', // Added validation
        ]);

        $user = $request->user();
        $wallet = Wallet::where('user_id', $user->id)->firstOrFail();

        if ($wallet->balance < $request->amount) {
            return response()->json(['message' => 'Insufficient balance'], 400);
        }

        // Restriction: Student can only withdraw on 15th of the month
        if ($user->role === 'student' && now()->day !== 15) {
             return response()->json(['message' => 'Học viên chỉ được rút tiền vào ngày 15 hàng tháng.'], 403);
        }

        DB::transaction(function () use ($user, $wallet, $request) {
            // 1. Deduct Balance (Hold)
            $wallet->balance -= $request->amount;
            $wallet->save();

            // 2. Create Request
            \App\Models\WithdrawalRequest::create([
                'user_id' => $user->id,
                'amount' => $request->amount,
                'bank_name' => $request->bank_name,
                'bank_account_number' => $request->account_number,
                'bank_account_name' => $request->account_name,
                'status' => 'pending'
            ]);

            // 3. Create Transaction Log (Pending)
            Transaction::create([
                'wallet_id' => $wallet->id,
                'amount' => -$request->amount,
                'type' => 'withdrawal',
                'description' => "Yêu cầu rút về {$request->bank_name}",
                'status' => 'pending'
            ]);
        });

        return response()->json(['success' => true, 'balance' => $wallet->balance, 'message' => 'Yêu cầu rút tiền đã được gửi.']);
    }
}
