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
        if (!Schema::hasTable('assignments')) {
            Schema::create('assignments', function (Blueprint $table) {
                $table->id();
                $table->foreignId('course_id')->constrained()->onDelete('cascade');
                $table->string('title');
                $table->text('description')->nullable();
                $table->dateTime('due_date')->nullable();
                $table->string('attachment_url')->nullable(); // File URL uploaded by Tutor
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('assignment_submissions')) {
            Schema::create('assignment_submissions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('assignment_id')->constrained()->onDelete('cascade');
                $table->foreignId('student_id')->constrained('users')->onDelete('cascade'); // Student who submitted
                $table->text('content')->nullable(); // Text submission
                $table->string('file_url')->nullable(); // File/Image submission
                $table->timestamp('submitted_at')->useCurrent();
                $table->decimal('grade', 5, 2)->nullable(); // Grade
                $table->text('feedback')->nullable(); // Tutor feedback
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('assignment_submissions');
        Schema::dropIfExists('assignments');
    }
};
