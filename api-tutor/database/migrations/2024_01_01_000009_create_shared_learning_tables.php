<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        // 1. Courses (Lớp học do Gia sư mở)
        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tutor_id')->constrained('tutors')->cascadeOnDelete();
            $table->string('title');
            $table->text('description');
            $table->decimal('price', 15, 2);
            $table->integer('max_students')->default(10);
            $table->date('start_date');
            $table->string('schedule'); // e.g. "Mon-Wed 19:00"
            $table->enum('status', ['open', 'ongoing', 'closed'])->default('open');
            $table->timestamps();
        });

        // 2. Study Groups (Nhóm học tập do Học sinh tạo)
        Schema::create('study_groups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('creator_id')->constrained('users')->cascadeOnDelete();
            $table->string('topic'); // e.g. "Ôn thi Đại học khối A"
            $table->string('subject');
            $table->string('grade_level');
            $table->integer('max_members')->default(5);
            $table->integer('current_members')->default(1); // Including creator
            $table->text('description')->nullable();
            $table->enum('status', ['open', 'full', 'closed'])->default('open');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('study_groups');
        Schema::dropIfExists('courses');
    }
};
