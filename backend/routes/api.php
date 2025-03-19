// Маршруты для уведомлений
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/notifications/register', [NotificationController::class, 'register']);
    Route::post('/notifications/unregister', [NotificationController::class, 'unregister']);
    Route::post('/notifications/test', [NotificationController::class, 'sendTestNotification']);
}); 