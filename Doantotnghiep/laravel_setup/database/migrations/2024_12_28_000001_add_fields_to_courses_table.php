<?php

/**
 * Migration: Add missing fields to courses table
 * 
 * **Purpose:**
 * - Thêm các fields còn thiếu vào bảng courses
 * - subject: Môn học
 * - grade_level: Cấp độ (Lớp 1, Lớp 12, Đại học, v.v.)
 * - mode: Hình thức học (Online, Offline)
 * - address: Địa điểm học (nếu Offline)
 * 
 * **Note:**
 * - Migration này an toàn, có thể chạy nhiều lần (kiểm tra column_exists)
 */
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
        Schema::table('courses', function (Blueprint $table) {
            // Thêm subject nếu chưa có
            if (!Schema::hasColumn('courses', 'subject')) {
                $table->string('subject')->nullable()->after('description');
            }
            
            // Thêm grade_level nếu chưa có
            if (!Schema::hasColumn('courses', 'grade_level')) {
                $table->string('grade_level')->nullable()->after('subject');
            }
            
            // Thêm mode nếu chưa có
            if (!Schema::hasColumn('courses', 'mode')) {
                $table->string('mode')->default('Offline')->after('schedule');
            }
            
            // Thêm address nếu chưa có
            if (!Schema::hasColumn('courses', 'address')) {
                $table->string('address')->nullable()->after('mode');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('courses', function (Blueprint $table) {
            if (Schema::hasColumn('courses', 'address')) {
                $table->dropColumn('address');
            }
            if (Schema::hasColumn('courses', 'mode')) {
                $table->dropColumn('mode');
            }
            if (Schema::hasColumn('courses', 'grade_level')) {
                $table->dropColumn('grade_level');
            }
            if (Schema::hasColumn('courses', 'subject')) {
                $table->dropColumn('subject');
            }
        });
    }
};






