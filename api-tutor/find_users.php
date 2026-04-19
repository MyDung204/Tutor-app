<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$names = ['Student1', 'Student6'];
foreach ($names as $name) {
    $user = \App\Models\User::where('name', 'LIKE', "%$name%")->orWhere('email', 'LIKE', "%$name%")->first();
    if ($user) {
        echo "User '$name': ID={$user->id}, DeviceToken=" . ($user->device_token ? 'YES' : 'NO') . "\n";
    } else {
        echo "User '$name': Not found\n";
    }
}
