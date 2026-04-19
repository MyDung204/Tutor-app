<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::table('study_groups', function (Blueprint $table) {
            $table->string('location')->nullable()->after('grade_level');
            $table->decimal('price', 15, 2)->default(0)->after('location');
        });
    }

    public function down()
    {
        Schema::table('study_groups', function (Blueprint $table) {
            $table->dropColumn(['location', 'price']);
        });
    }
};
