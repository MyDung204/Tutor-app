<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique(); // e.g., "certified-tutor"
            $table->string('icon_url')->nullable();
            $table->string('description')->nullable();
            $table->string('color_hex')->default('#FFD700'); // Hex color code
            $table->timestamps();
        });

        Schema::create('tutor_badges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('badge_id')->constrained('badges')->onDelete('cascade');
            $table->timestamp('awarded_at')->useCurrent();
            $table->unique(['user_id', 'badge_id']);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('tutor_badges');
        Schema::dropIfExists('badges');
    }
};
