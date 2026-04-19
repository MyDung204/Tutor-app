<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up()
    {
        Schema::create('tutors', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('avatar_url')->nullable();
            $table->text('bio')->nullable();
            $table->double('hourly_rate');
            $table->double('rating')->default(0);
            $table->integer('review_count')->default(0);
            $table->string('location');
            $table->string('address')->nullable();
            $table->string('gender')->nullable();
            $table->boolean('is_verified')->default(false);
            $table->json('subjects');
            $table->json('teaching_mode');
            $table->json('weekly_schedule')->nullable();
            $table->timestamps();
        });
    }
    public function down()
    {
        Schema::dropIfExists('tutors');
    }
};
