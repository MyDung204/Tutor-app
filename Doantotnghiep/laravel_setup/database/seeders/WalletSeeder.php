<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Wallet;
use App\Models\Transaction;
use App\Models\User;

class WalletSeeder extends Seeder
{
    public function run()
    {
        $users = User::all();

        foreach ($users as $user) {
            $wallet = Wallet::create([
                'user_id' => $user->id,
                'balance' => 5000000, // 5 million VND default
            ]);

            // Add dummy transactions
            Transaction::create([
                'wallet_id' => $wallet->id,
                'amount' => 5000000,
                'type' => 'deposit',
                'description' => 'Nạp tiền lần đầu',
                'status' => 'success',
                'created_at' => now()->subDays(5)
            ]);

            Transaction::create([
                'wallet_id' => $wallet->id,
                'amount' => 200000,
                'type' => 'payment',
                'description' => 'Thanh toán khóa học Toán',
                'status' => 'success',
                'created_at' => now()->subDays(2)
            ]);
        }
    }
}
