<?php

namespace App\Services;

use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Firebase\ServiceAccount;
use Kreait\Firebase\Factory;

class FirebaseService
{
    private $messaging;

    public function __construct()
    {
        $factory = (new Factory)
            ->withServiceAccount(storage_path('firebase-credentials.json'));

        $this->messaging = $factory->createMessaging();
    }

    public function sendNotification($deviceToken, $title, $body, $data = [])
    {
        try {
            $message = CloudMessage::withTarget('token', $deviceToken)
                ->withNotification(
                    Notification::create($title, $body)
                )
                ->withData($data);

            $this->messaging->send($message);
            return true;
        } catch (\Exception $e) {
            \Log::error('Firebase notification error: ' . $e->getMessage());
            return false;
        }
    }

    public function sendNotificationToUser($userId, $title, $body, $data = [])
    {
        $deviceTokens = \App\Models\DeviceToken::where('user_id', $userId)->get();
        
        foreach ($deviceTokens as $deviceToken) {
            $this->sendNotification($deviceToken->device_token, $title, $body, $data);
        }
    }

    public function sendNotificationToMultipleUsers($userIds, $title, $body, $data = [])
    {
        foreach ($userIds as $userId) {
            $this->sendNotificationToUser($userId, $title, $body, $data);
        }
    }
} 