<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$userId = 4; // Tuning for User 4 (likely the Tutor/Creator)
echo "Checking notifications for User ID: $userId\n";

$count = \App\Models\AppNotification::where('user_id', $userId)->count();
echo "Total Notifications: $count\n";

$latest = \App\Models\AppNotification::where('user_id', $userId)
    ->latest()
    ->take(5)
    ->get();

foreach ($latest as $n) {
    echo "[{$n->created_at}] Type: {$n->type} | Title: {$n->title} | Body: {$n->body}\n";
}
