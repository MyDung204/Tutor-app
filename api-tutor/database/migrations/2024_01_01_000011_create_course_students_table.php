<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * 
     * Tạo bảng course_students để lưu thông tin học viên đăng ký lớp học
     * 
     * **Purpose:**
     * - Lưu danh sách học viên đã đăng ký vào các lớp học
     * - Theo dõi trạng thái đăng ký (pending, approved, rejected)
     * - Quản lý số lượng học viên trong mỗi lớp
     */
    public function up(): void
    {
        Schema::create('course_students', function (Blueprint $table) {
            $table->id();
            $table->foreignId('course_id')->constrained('courses')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->timestamp('enrolled_at')->useCurrent();
            $table->timestamps();

            // Unique constraint: Mỗi học viên chỉ có thể đăng ký một lần cho mỗi lớp
            $table->unique(['course_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('course_students');
    }
};

