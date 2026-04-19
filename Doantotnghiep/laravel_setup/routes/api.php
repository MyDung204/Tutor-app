<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TutorController;
use App\Http\Controllers\Api\QuestionController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SharedLearningController;
use App\Http\Controllers\Api\AdminController;

// ... existing code ...

// Admin Routes
Route::prefix('admin')->group(function () {
    Route::get('/stats', [AdminController::class, 'stats']);
    Route::get('/users', [AdminController::class, 'users']);
    Route::post('/users/{id}/ban', [AdminController::class, 'toggleBan']);

    // Tutor Approval
    Route::get('/tutor-requests', [AdminController::class, 'tutorRequests']);
    Route::post('/tutors/{id}/approve', [AdminController::class, 'approveTutor']);
    Route::post('/tutors/{id}/reject', [AdminController::class, 'rejectTutor']);

    // Reports
    Route::get('/reports', [AdminController::class, 'reports']);
    Route::post('/reports/{id}/resolve', [AdminController::class, 'resolveReport']);

    // Audit Logs
    Route::get('/audit-logs', [AdminController::class, 'getAuditLogs']);
});


Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->get('/user', [AuthController::class, 'me']);

Route::get('/debug-tutors', function () {
    return \App\Models\Tutor::all();
});

// Shared Learning - Study Groups
Route::get('/study-groups', [SharedLearningController::class, 'indexGroups']);
Route::middleware('auth:sanctum')->get('/my-study-groups', [SharedLearningController::class, 'myStudyGroups']);
Route::middleware('auth:sanctum')->post('/study-groups', [SharedLearningController::class, 'storeGroup']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/join', [SharedLearningController::class, 'joinGroup']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/members/{userId}/approve', [SharedLearningController::class, 'approveMember']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/members/{userId}/reject', [SharedLearningController::class, 'rejectMember']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/leave', [SharedLearningController::class, 'leaveGroup']);
Route::get('/study-groups/{id}/members', [SharedLearningController::class, 'getGroupMembers']);

// Shared Learning - Courses (Lớp học)
Route::get('/courses', [SharedLearningController::class, 'indexCourses']);
Route::middleware('auth:sanctum')->post('/courses', [SharedLearningController::class, 'storeCourse']);
Route::middleware('auth:sanctum')->put('/courses/{id}', [SharedLearningController::class, 'updateCourse']);
Route::middleware('auth:sanctum')->delete('/courses/{id}', [SharedLearningController::class, 'destroyCourse']);
Route::middleware('auth:sanctum')->post('/courses/{id}/join', [SharedLearningController::class, 'joinCourse']);
Route::middleware('auth:sanctum')->post('/courses/{id}/leave', [SharedLearningController::class, 'leaveCourse']);
Route::middleware('auth:sanctum')->get('/my-courses', [SharedLearningController::class, 'myCourses']);

Route::get('/tutors', [TutorController::class, 'index']);
Route::get('/tutors/{id}', [TutorController::class, 'show']);
Route::get('/questions', [QuestionController::class, 'index']);
Route::post('/questions', [QuestionController::class, 'store']);
Route::post('/questions/{id}/answers', [QuestionController::class, 'storeAnswer']);
Route::get('/bookings', [BookingController::class, 'index']);
Route::post('/bookings/lock', [BookingController::class, 'lockSlot']);
Route::post('/bookings/{id}/confirm', [BookingController::class, 'confirm']);
Route::post('/bookings/{id}/cancel', [BookingController::class, 'cancel']);

// Chat
Route::get('/conversations', [App\Http\Controllers\Api\ChatController::class, 'index']);
Route::get('/conversations/{id}/messages', [App\Http\Controllers\Api\ChatController::class, 'show']);
Route::post('/messages', [App\Http\Controllers\Api\ChatController::class, 'store']);

// Wallet
Route::get('/wallet', [App\Http\Controllers\Api\WalletController::class, 'index']);
Route::post('/wallet/deposit', [App\Http\Controllers\Api\WalletController::class, 'deposit']);

// Tutor Requests
Route::middleware('auth:sanctum')->post('/tutor-requests', [App\Http\Controllers\Api\TutorRequestController::class, 'store']);
Route::get('/tutor-requests', [App\Http\Controllers\Api\TutorRequestController::class, 'index']);
Route::middleware('auth:sanctum')->get('/my-tutor-requests', [App\Http\Controllers\Api\TutorRequestController::class, 'myRequests']);
Route::middleware('auth:sanctum')->delete('/tutor-requests/{id}', [App\Http\Controllers\Api\TutorRequestController::class, 'destroy']);
