<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->string('reporter_id'); // User ID who reported
            $table->string('reporter_name');
            $table->string('target_id')->nullable(); // ID of reported entity (tutor/user)
            $table->string('target_name')->nullable();
            $table->string('reason'); // e.g., 'Inappropriate behavior', 'Spam'
            $table->text('description')->nullable();
            $table->string('status')->default('pending');
            $table->string('type')->default('tutor_report');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('reports');
    }
};
