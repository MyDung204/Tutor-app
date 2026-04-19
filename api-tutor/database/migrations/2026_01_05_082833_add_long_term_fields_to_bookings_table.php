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
        Schema::table('bookings', function (Blueprint $table) {
            $table->enum('type', ['single', 'long_term'])->default('single');
            $table->unsignedBigInteger('parent_id')->nullable();
            $table->enum('learning_mode', ['online', 'offline'])->default('online');
            
            $table->foreign('parent_id')->references('id')->on('bookings')->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropForeign(['parent_id']);
            $table->dropColumn(['type', 'parent_id', 'learning_mode']);
        });
    }
};
