<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('tutor_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->string('subject');
            $table->string('grade_level');
            $table->text('description');
            $table->decimal('min_budget', 15, 2)->nullable();
            $table->decimal('max_budget', 15, 2)->nullable();
            $table->string('schedule')->nullable();
            $table->string('location')->nullable();
            $table->enum('mode', ['Online', 'Offline', 'Any'])->default('Any');
            $table->enum('status', ['open', 'closed', 'matched'])->default('open');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('tutor_requests');
    }
};
