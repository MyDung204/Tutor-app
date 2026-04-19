<?php

/**
 * Migration: Add missing fields to study_groups table
 * 
 * **Purpose:**
 * - Thêm các fields còn thiếu vào bảng study_groups
 * - location: Khu vực (Online, Hà Nội, TP.HCM, Q.1, v.v.)
 * - price: Giá mỗi buổi học (VND)
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
        Schema::table('study_groups', function (Blueprint $table) {
            // Thêm location nếu chưa có
            if (!Schema::hasColumn('study_groups', 'location')) {
                $table->string('location')->nullable()->after('grade_level');
            }
            
            // Thêm price nếu chưa có
            if (!Schema::hasColumn('study_groups', 'price')) {
                $table->decimal('price', 15, 2)->default(0)->after('description');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('study_groups', function (Blueprint $table) {
            if (Schema::hasColumn('study_groups', 'price')) {
                $table->dropColumn('price');
            }
            if (Schema::hasColumn('study_groups', 'location')) {
                $table->dropColumn('location');
            }
        });
    }
};






