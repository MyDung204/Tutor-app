<?php
require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$tutor = App\Models\Tutor::where('user_id', 4)->first();
if ($tutor) {
    echo "TutorID:" . $tutor->id . "\n";
    echo "Count:" . $tutor->availabilities()->count() . "\n";
    echo $tutor->availabilities->toJson();
} else {
    echo "TutorNotFound";
}
