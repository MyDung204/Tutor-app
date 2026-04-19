<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('questions', function (Blueprint $table) {
            $table->id(); // String ID in Flutter but usually Int in SQL. Let's use AutoInc for simplicity.
            $table->string('user_id'); // Link to Users table (if exists)
            $table->string('user_name')->nullable();
            $table->string('user_avatar')->nullable();
            $table->string('subject');
            $table->text('content');
            $table->string('image_url')->nullable();
            $table->integer('like_count')->default(0);
            $table->integer('answer_count')->default(0);
            $table->boolean('is_solved')->default(false);
            $table->timestamps();
        });

        Schema::create('answers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('question_id')->constrained()->onDelete('cascade');
            $table->string('user_id');
            $table->string('user_name')->nullable();
            $table->string('user_avatar')->nullable();
            $table->text('content');
            $table->boolean('is_accepted')->default(false);
            $table->integer('like_count')->default(0);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('answers');
        Schema::dropIfExists('questions');
    }
};
