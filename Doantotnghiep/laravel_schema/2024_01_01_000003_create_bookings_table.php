<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tutor_id')->constrained()->onDelete('cascade');
            $table->string('user_id'); // Student
            $table->dateTime('date');
            $table->string('time_slot'); // "08:00 - 10:00"
            $table->double('price');
            $table->string('status')->default('Upcoming'); // Upcoming, Locked, Cancelled, Completed
            $table->dateTime('locked_until')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('bookings');
    }
};
