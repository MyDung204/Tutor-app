<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::table('tutors', function (Blueprint $table) {
            $table->unsignedBigInteger('user_id')->nullable()->after('id');
            // Make fields nullable
            $table->double('hourly_rate')->default(0)->change();
            $table->string('location')->nullable()->change();
            $table->json('subjects')->nullable()->change();
            $table->json('teaching_mode')->nullable()->change();

            // Foreign key
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::table('tutors', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn('user_id');
            // Reverting nullable is hard without knowing original state exactly, skipping strict revert.
        });
    }
};
