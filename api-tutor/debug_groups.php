<?php

use App\Models\User;
use App\Models\StudyGroup;
use Illuminate\Support\Facades\DB;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Assume User 39 is Student1 (Creator) - based on previous context
$userId = 39; 
$user = User::find($userId);

if (!$user) {
    echo "User $userId not found.\n";
    exit;
}

echo "Checking Groups for User: {$user->name} (ID: $userId)\n";

// replicate myStudyGroups logic
$groupIds = DB::table('study_group_members')
    ->where('user_id', $user->id)
    ->whereIn('status', ['approved', 'pending'])
    ->pluck('study_group_id')
    ->toArray();

echo "Group IDs found: " . implode(', ', $groupIds) . "\n";

$groups = StudyGroup::whereIn('id', $groupIds)->latest()->get();

foreach ($groups as $group) {
    echo "\n------------------------------------------------\n";
    echo "Group ID: {$group->id} | Topic: {$group->topic}\n";
    echo "Creator ID: {$group->creator_id}\n";
    
    $isCreator = ($group->creator_id == $user->id);
    echo "Is Creator? " . ($isCreator ? "YES" : "NO") . "\n";

    $pendingCount = DB::table('study_group_members')
        ->where('study_group_id', $group->id)
        ->where('status', 'pending')
        ->count();
        
    echo "Pending Members Count (DB): $pendingCount\n";
    
    // Check specific pending members
    $pendingMembers = DB::table('study_group_members')
        ->join('users', 'study_group_members.user_id', '=', 'users.id')
        ->where('study_group_id', $group->id)
        ->where('study_group_members.status', 'pending')
        ->select('users.id', 'users.name')
        ->get();
        
    if ($pendingMembers->count() > 0) {
        echo "Pending Users:\n";
        foreach($pendingMembers as $pm) {
            echo "- {$pm->name} (ID: {$pm->id})\n";
        }
    } else {
        echo "No pending users.\n";
    }
}
