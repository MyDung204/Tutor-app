<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add pending/rejected to ENUM
        // Since Laravel doesn't support changing ENUM values easily with Schema builder for existing columns in all drivers,
        // we use raw SQL or Doctrine. For MySQL:
        DB::statement("ALTER TABLE courses MODIFY COLUMN status ENUM('pending', 'open', 'ongoing', 'closed', 'rejected') DEFAULT 'pending'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement("ALTER TABLE courses MODIFY COLUMN status ENUM('open', 'ongoing', 'closed') DEFAULT 'open'");
    }
};
