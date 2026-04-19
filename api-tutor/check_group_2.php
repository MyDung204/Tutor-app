<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$groupId = 2; 
$group = \App\Models\StudyGroup::find($groupId);

if ($group) {
    echo "Group 2 Creator ID: " . $group->creator_id . "\n";
    
    // Check Notifications for Creator
    $count = \App\Models\AppNotification::where('user_id', $group->creator_id)->count();
    echo "Notifications for Creator ({$group->creator_id}): $count\n";
    
    $latest = \App\Models\AppNotification::where('user_id', $group->creator_id)->latest()->take(3)->get();
    foreach($latest as $n) {
        echo " - [{$n->created_at}] {$n->title}: {$n->body}\n";
    }
} else {
    echo "Group 2 not found.\n";
}
