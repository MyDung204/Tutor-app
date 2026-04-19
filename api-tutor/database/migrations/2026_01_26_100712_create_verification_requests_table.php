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
        Schema::create('verification_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type')->default('student_card'); // 'student_card', 'tutor_card', 'cccd'
            $table->string('front_image_url');
            $table->string('back_image_url');
            $table->string('status')->default('pending'); // 'pending', 'approved', 'rejected'
            $table->text('note')->nullable(); // Reject reason
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('identity_verified_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('identity_verified_at');
        });
        
        Schema::dropIfExists('verification_requests');
    }
};
