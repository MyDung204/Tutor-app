<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('tutors', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('avatar_url')->nullable();
            $table->text('bio')->nullable();
            $table->double('hourly_rate'); // Giá theo giờ
            $table->double('rating')->default(0);
            $table->integer('review_count')->default(0);
            $table->string('location');
            $table->string('address')->nullable();
            $table->string('gender')->nullable();
            $table->boolean('is_verified')->default(false);
            
            // JSON fields for Arrays
            $table->json('subjects'); // ['Toán', 'Lý'...]
            $table->json('teaching_mode'); // ['Online', 'Offline']
            $table->json('weekly_schedule')->nullable(); // {'2': ['08:00...']}
            
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('tutors');
    }
};
