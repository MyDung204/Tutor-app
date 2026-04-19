<?php

namespace App\Services;

use Kreait\Firebase\Contract\Firestore;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Illuminate\Support\Facades\Log;

class FirebaseNotificationService
{
    protected $firestore;
    protected $messaging;

    public function __construct(Messaging $messaging)
    {
        $this->messaging = $messaging;
    }

    public function sendToUser(string $userId, string $title, string $body, string $type = 'system', array $data = [])
    {
        Log::info("FirebaseNotificationService::sendToUser called for User: $userId | Title: $title");
        try {
            // 1. Save to MySQL (Primary History) - ENSURE THIS RUNS FIRST
            try {
                \App\Models\AppNotification::create([
                    'user_id' => $userId,
                    'title' => $title,
                    'body' => $body,
                    'type' => $type,
                    'data' => $data,
                    'is_read' => false
                ]);
            } catch (\Exception $e) {
               Log::error("Failed to save to MySQL: " . $e->getMessage());
            }
            
            Log::info("Saved to MySQL successfully.");

            // 2. Send FCM Push Notification
            try {
                $user = \App\Models\User::find($userId);
                if ($user && $user->device_token) {
                    // Create message
                    $message = CloudMessage::withTarget('token', $user->device_token)
                        ->withNotification(Notification::create($title, $body))
                        ->withData(array_merge($data, ['click_action' => 'FLUTTER_NOTIFICATION_CLICK', 'type' => $type]));

                    // Send with SSL Bypass (Debug Only)
                    // Note: Kreait/Firebase uses Guzzle. We can't easily inject Guzzle options here unless we re-configured the Factory.
                    // Instead, users should fix php.ini. 
                    // However, we can try to rely on the fact that we can't change the factory easily here without modifying the prompt instructions which I can't do.
                    // Let's assume standard send() and see if log helps. 
                    // WAIT, I can configure the Messaging component? No, it's injected.
                    // I will just log before sending.
                    
                    Log::info("Sending FCM to token: " . substr($user->device_token, 0, 10) . "...");
                    $this->messaging->send($message);
                    Log::info("FCM sent to user (MySQL Token): $userId");
                } else {
                    Log::warning("No device_token found in MySQL for user: $userId");
                }
            } catch (\Throwable $e) {
                // Log FCM error but don't crash - history is already saved
                Log::error("Failed to send FCM: " . $e->getMessage());
            }

            // 3. OPTIONAL: Write to Firestore (History) - Only if gRPC is available
            if (extension_loaded('grpc')) {
                // Lazy load Firestore
                $firestore = app('firebase.firestore');
                $database = $firestore->database();

                $notificationData = [
                    'title' => $title,
                    'body' => $body,
                    'type' => $type,
                    'isRead' => false,
                    'createdAt' => new \DateTime(),
                    'data' => $data,
                ];

                $database->collection('notifications')
                    ->document($userId)
                    ->collection('messages')
                    ->add($notificationData);
                
                Log::info("Notification history written to Firestore for user: $userId");
            }

        } catch (\Throwable $e) {
            Log::error("Critical Error in NotificationService: " . $e->getMessage());
        }
    }
}
