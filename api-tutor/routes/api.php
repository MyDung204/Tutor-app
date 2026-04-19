<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TutorController;
use App\Http\Controllers\Api\QuestionController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\SharedLearningController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\WalletController; // Added this import

// ... existing code ...

// Admin Routes
Route::prefix('admin')->group(function () {
    Route::get('/stats', [AdminController::class, 'stats']);
    Route::get('/users', [AdminController::class, 'users']);
    Route::get('/users/{id}', [AdminController::class, 'showUser']); // NEW
    Route::put('/users/{id}', [AdminController::class, 'updateUser']); // NEW
    // Smart Matching
    Route::post('/smart-match', [App\Http\Controllers\Api\SmartMatchController::class, 'getMatches']);
    Route::post('/user/learning-tags', [App\Http\Controllers\Api\SmartMatchController::class, 'saveTags']);

    // Community Q&A
    Route::apiResource('questions', App\Http\Controllers\Api\CommunityController::class)->only(['index', 'store', 'show']);
    Route::post('/questions/{id}/answers', [App\Http\Controllers\Api\CommunityController::class, 'storeAnswer']); // NEW
    Route::get('/users/{id}/activities', [AdminController::class, 'getUserActivities']); // NEW
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

    // Course Approval
    Route::get('/courses/pending', [AdminController::class, 'pendingCourses']);
    Route::post('/courses/{id}/approve', [AdminController::class, 'approveCourse']);
    Route::post('/courses/{id}/reject', [AdminController::class, 'rejectCourse']);

    // Broadcast Notifications
    Route::post('/notifications/broadcast', [AdminController::class, 'broadcast']);

    // Financials
    Route::get('/withdrawals', [App\Http\Controllers\Api\AdminFinanceController::class, 'index']);
    Route::post('/withdrawals/{id}/approve', [App\Http\Controllers\Api\AdminFinanceController::class, 'approve']);
    Route::post('/withdrawals/{id}/reject', [App\Http\Controllers\Api\AdminFinanceController::class, 'reject']);

    // System Data
    Route::get('/system/subjects', [App\Http\Controllers\Api\AdminSystemController::class, 'subjects']);
    Route::post('/system/subjects', [App\Http\Controllers\Api\AdminSystemController::class, 'storeSubject']);
    Route::put('/system/subjects/{id}', [App\Http\Controllers\Api\AdminSystemController::class, 'updateSubject']);
    Route::delete('/system/subjects/{id}', [App\Http\Controllers\Api\AdminSystemController::class, 'destroySubject']);
});


Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->get('/user', [AuthController::class, 'me']);
Route::middleware('auth:sanctum')->post('/device-token', [AuthController::class, 'updateDeviceToken']);

Route::middleware('auth:sanctum')->post('/device-token', [AuthController::class, 'updateDeviceToken']);

// Shared Learning
Route::get('/study-groups', [SharedLearningController::class, 'indexGroups']);
Route::middleware('auth:sanctum')->get('/my-study-groups', [SharedLearningController::class, 'myStudyGroups']);
Route::get('/courses', [SharedLearningController::class, 'indexCourses']);
Route::middleware('auth:sanctum')->post('/courses', [SharedLearningController::class, 'storeCourse']);
Route::middleware('auth:sanctum')->post('/courses/{id}/join', [SharedLearningController::class, 'joinCourse']);
Route::middleware('auth:sanctum')->post('/courses/{id}/leave', [SharedLearningController::class, 'leaveCourse']);
Route::middleware('auth:sanctum')->post('/courses/{id}/kick', [SharedLearningController::class, 'removeStudentFromCourse']); // Kick Student
Route::middleware('auth:sanctum')->post('/courses/{id}/tuition/refuse', [SharedLearningController::class, 'refuseTuition']); // Refuse Tuition (Grace Period)
Route::middleware('auth:sanctum')->get('/my-courses', [SharedLearningController::class, 'myCourses']);
Route::middleware('auth:sanctum')->post('/study-groups', [SharedLearningController::class, 'storeGroup']);
Route::middleware('auth:sanctum')->put('/study-groups/{id}', [SharedLearningController::class, 'updateGroup']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/join', [SharedLearningController::class, 'joinGroup']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/members/{userId}/approve', [SharedLearningController::class, 'approveMember']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/members/{userId}/reject', [SharedLearningController::class, 'rejectMember']);
Route::middleware('auth:sanctum')->delete('/study-groups/{id}/members/{userId}', [SharedLearningController::class, 'removeMember']);
Route::middleware('auth:sanctum')->post('/study-groups/{id}/leave', [SharedLearningController::class, 'leaveGroup']);
Route::get('/study-groups/{id}/members', [SharedLearningController::class, 'getGroupMembers']);

Route::get('/tutors', [TutorController::class, 'index']);
Route::get('/tutors/{id}', [TutorController::class, 'show'])->where('id', '[0-9]+');
Route::get('/questions', [QuestionController::class, 'index']);
Route::post('/questions', [QuestionController::class, 'store']);
Route::post('/questions/{id}/answers', [QuestionController::class, 'storeAnswer']);

Route::get('/tutors/{id}/availability', [TutorController::class, 'getAvailability'])->where('id', '[0-9]+'); // Public

// New routes for favorites
Route::middleware('auth:sanctum')->group(function() {
    Route::post('/tutors/{id}/favorite', [TutorController::class, 'toggleFavorite']);
    Route::get('/favorites/tutors', [TutorController::class, 'getFavorites']);
});

// Protected Booking Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/tutors/my-availability', [TutorController::class, 'getMyAvailability']);
    Route::post('/tutors/availability', [TutorController::class, 'updateAvailability']);

    Route::get('/bookings', [BookingController::class, 'index']);
    Route::post('/bookings/lock', [BookingController::class, 'lockSlot']);
    Route::post('/bookings/{id}/confirm', [BookingController::class, 'confirm']);
    Route::post('/bookings/{id}/reject', [BookingController::class, 'reject']);
    Route::post('/bookings/{id}/cancel', [BookingController::class, 'cancel']);
    Route::post('/bookings/{id}/session-info', [BookingController::class, 'updateSessionInfo']);
});

// Chat
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/conversations', [App\Http\Controllers\Api\ChatController::class, 'index']);
    Route::get('/conversations/{id}/messages', [App\Http\Controllers\Api\ChatController::class, 'show']);
    Route::post('/messages', [App\Http\Controllers\Api\ChatController::class, 'store']);
    Route::post('/chat/upload', [App\Http\Controllers\Api\ChatController::class, 'upload']);
    Route::post('/chat/offer/accept', [App\Http\Controllers\Api\ChatController::class, 'acceptOffer']);
});

// Wallet
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/wallet', [App\Http\Controllers\Api\WalletController::class, 'index']);
    Route::post('/wallet/deposit', [App\Http\Controllers\Api\WalletController::class, 'deposit']);
    Route::post('/wallet/withdraw', [App\Http\Controllers\Api\WalletController::class, 'withdraw']);
    
    // PIN System
    Route::post('/wallet/pin/setup', [App\Http\Controllers\Api\WalletController::class, 'setupPin']);
    Route::post('/wallet/pin/change', [App\Http\Controllers\Api\WalletController::class, 'changePin']);
    Route::post('/wallet/pin/verify', [App\Http\Controllers\Api\WalletController::class, 'verifyPin']);

    Route::post('/tutors/update-profile', [TutorController::class, 'updateProfile']);
    Route::post('/tutors/upload-material', [TutorController::class, 'uploadMaterial']);
});

// Tutor Requests
Route::middleware('auth:sanctum')->post('/tutor-requests', [App\Http\Controllers\Api\TutorRequestController::class, 'store']);
Route::get('/tutor-requests', [App\Http\Controllers\Api\TutorRequestController::class, 'index']);
Route::middleware('auth:sanctum')->get('/my-tutor-requests', [App\Http\Controllers\Api\TutorRequestController::class, 'myRequests']);
Route::middleware('auth:sanctum')->delete('/tutor-requests/{id}', [App\Http\Controllers\Api\TutorRequestController::class, 'destroy']);

// Tutor specific stats & tuitions
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/tutors/my-statistics', [TutorController::class, 'myStatistics']);
    Route::get('/tutors/my-tuitions', [TutorController::class, 'myTuitions']);
});

// Test Notification
Route::post('/send-notification', function (Illuminate\Http\Request $request, App\Services\FirebaseNotificationService $service) {
    $request->validate([
        'user_id' => 'required',
        'title' => 'required',
        'body' => 'required',
    ]);

    $service->sendToUser(
        $request->user_id,
        $request->title,
        $request->body,
        $request->input('type', 'system'),
        $request->input('data', [])
    );

    return response()->json(['message' => 'Notification sent']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/notifications', [App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read', [App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);

    // Assignments
    Route::get('/courses/{courseId}/assignments', [App\Http\Controllers\AssignmentController::class, 'index']);
    Route::post('/assignments', [App\Http\Controllers\AssignmentController::class, 'store']);
    Route::post('/assignments/{id}/submit', [App\Http\Controllers\AssignmentController::class, 'submit']);
    Route::get('/assignments/{id}/submissions', [App\Http\Controllers\AssignmentController::class, 'submissions']);
    Route::delete('/assignments/{id}', [App\Http\Controllers\AssignmentController::class, 'destroy']);

    // Announcements
    Route::get('/courses/{id}/announcements', [SharedLearningController::class, 'indexAnnouncements']);
    Route::post('/courses/{id}/announcements', [SharedLearningController::class, 'storeAnnouncement']);

    // Quiz System
    Route::get('/quizzes', [App\Http\Controllers\Api\QuizController::class, 'index']);
    Route::get('/quizzes/{id}', [App\Http\Controllers\Api\QuizController::class, 'show']);
    Route::post('/quizzes', [App\Http\Controllers\Api\QuizController::class, 'store']); // Tutor only
    Route::post('/quizzes/{id}/submit', [App\Http\Controllers\Api\QuizController::class, 'submit']); // Student only
    Route::get('/my-quiz-attempts', [App\Http\Controllers\Api\QuizController::class, 'attempts']);

    // Smart Matching
    Route::get('/smart-matching/request/{id}', [App\Http\Controllers\Api\SmartMatchingController::class, 'matchTutorsForRequest']);
    Route::get('/smart-matching/tutor', [App\Http\Controllers\Api\SmartMatchingController::class, 'matchRequestsForTutor']);

    // Map System
    Route::post('/map/update-location', [App\Http\Controllers\Api\MapController::class, 'updateLocation']);
    Route::get('/map/nearby', [App\Http\Controllers\Api\MapController::class, 'getNearbyUsers']);

    // Payment Sandbox (Protected)
    Route::post('/payment/simulate', [App\Http\Controllers\Api\PaymentController::class, 'simulate']);

    // Verification (eKYC)
    Route::post('/verification/submit', [App\Http\Controllers\Api\VerificationController::class, 'submit']);
    Route::get('/verification/status', [App\Http\Controllers\Api\VerificationController::class, 'getStatus']);
    // Admin Routes (Should be protected by admin middleware, keeping here for now)
    Route::post('/verification/{id}/approve', [App\Http\Controllers\Api\VerificationController::class, 'approve']);
    Route::post('/verification/{id}/reject', [App\Http\Controllers\Api\VerificationController::class, 'reject']);
    Route::get('/verification/pending', [App\Http\Controllers\Api\VerificationController::class, 'listPending']);
});

// Public Webhook for Payment (simulating SePay/Casso calls)
Route::post('/payment/webhook', [App\Http\Controllers\Api\PaymentController::class, 'webhook']);
