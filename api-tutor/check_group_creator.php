<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Check groups that User 44 has joined/applied to
$userId = 44;
echo "Checking groups for User $userId...\n";

$memberships = \DB::table('study_group_members')->where('user_id', $userId)->get();

foreach ($memberships as $m) {
    $group = \App\Models\StudyGroup::find($m->study_group_id);
    if ($group) {
        echo "Group ID: {$group->id} | Topic: {$group->topic} | Status: {$m->status}\n";
        echo " -> Creator ID: {$group->creator_id}\n";
        
        // Check notifications for this creator
        $count = \App\Models\AppNotification::where('user_id', $group->creator_id)->count();
        $latest = \App\Models\AppNotification::where('user_id', $group->creator_id)->latest()->first();
        echo " -> Creator's Notifications: $count\n";
        if ($latest) {
             echo " -> Latest Notif: {$latest->title} ({$latest->created_at})\n";
        }
    }
}
