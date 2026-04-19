<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('wallets', function (Blueprint $table) {
            $table->string('payment_pin')->nullable();
        });

        // Set default PIN '000000' for existing wallets
        DB::table('wallets')->update([
            'payment_pin' => \Illuminate\Support\Facades\Hash::make('000000')
        ]);
    }

    public function down(): void
    {
        Schema::table('wallets', function (Blueprint $table) {
             $table->dropColumn('payment_pin');
        });
    }
};
