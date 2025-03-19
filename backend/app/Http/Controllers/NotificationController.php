<?php

namespace App\Http\Controllers;

use App\Models\DeviceToken;
use App\Services\FirebaseService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    protected $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    public function register(Request $request)
    {
        $request->validate([
            'device_token' => 'required|string',
            'platform' => 'nullable|string',
        ]);

        $userId = Auth::id();
        $deviceToken = $request->device_token;
        $platform = $request->platform;

        // Удаляем старый токен, если он существует
        DeviceToken::where('device_token', $deviceToken)->delete();

        // Создаем новый токен
        DeviceToken::create([
            'user_id' => $userId,
            'device_token' => $deviceToken,
            'platform' => $platform,
        ]);

        return response()->json(['message' => 'Устройство успешно зарегистрировано']);
    }

    public function unregister(Request $request)
    {
        $request->validate([
            'device_token' => 'required|string',
        ]);

        $userId = Auth::id();
        $deviceToken = $request->device_token;

        DeviceToken::where('user_id', $userId)
            ->where('device_token', $deviceToken)
            ->delete();

        return response()->json(['message' => 'Устройство успешно удалено']);
    }

    public function sendTestNotification(Request $request)
    {
        $userId = Auth::id();
        
        $this->firebaseService->sendNotificationToUser(
            $userId,
            'Тестовое уведомление',
            'Это тестовое уведомление от LetsGo',
            ['type' => 'test']
        );

        return response()->json(['message' => 'Тестовое уведомление отправлено']);
    }
} 