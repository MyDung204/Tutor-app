<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TutorController;
use App\Http\Controllers\Api\QuestionController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\AuthController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Auth
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected Routes (Require Token)
Route::get('/debug-tutors', function () {
    return \App\Models\Tutor::all();
});
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'me']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
});

// Public Data
Route::get('/tutors', [TutorController::class, 'index']);
Route::get('/tutors/{id}', [TutorController::class, 'show']);

Route::get('/questions', [QuestionController::class, 'index']);
Route::post('/questions', [QuestionController::class, 'store']);
Route::post('/questions/{id}/answers', [QuestionController::class, 'storeAnswer']);

Route::get('/bookings', [BookingController::class, 'index']);
Route::post('/bookings/lock', [BookingController::class, 'lockSlot']);
Route::post('/bookings/{id}/confirm', [BookingController::class, 'confirm']);
Route::post('/bookings/{id}/cancel', [BookingController::class, 'cancel']);
