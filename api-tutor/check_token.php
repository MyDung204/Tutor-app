<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::find(44); // User ID from logs
if ($user) {
    echo "User found: " . $user->name . "\n";
    echo "Device Token: " . ($user->device_token ? substr($user->device_token, 0, 20) . '...' : 'NULL') . "\n";
} else {
    echo "User 44 not found.\n";
}

$user4 = \App\Models\User::find(4); // Tutor ID from previous logs
if ($user4) {
    echo "User 4 found: " . $user4->name . "\n";
    echo "Device Token: " . ($user4->device_token ? substr($user4->device_token, 0, 20) . '...' : 'NULL') . "\n";
}
