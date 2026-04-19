<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('course_students', function (Blueprint $table) {
            $table->date('next_payment_due')->nullable()->after('status');
            $table->enum('payment_status', ['paid', 'due', 'grace_period', 'overdue'])->default('paid')->after('next_payment_due');
            $table->dateTime('grace_period_ends_at')->nullable()->after('payment_status');
        });
    }

    public function down(): void
    {
        Schema::table('course_students', function (Blueprint $table) {
            $table->dropColumn(['next_payment_due', 'payment_status', 'grace_period_ends_at']);
        });
    }
};
