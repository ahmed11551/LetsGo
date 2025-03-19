<?php

namespace App\Http\Controllers;

use App\Models\Trip;
use App\Services\TripNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TripController extends Controller
{
    protected $tripNotificationService;

    public function __construct(TripNotificationService $tripNotificationService)
    {
        $this->tripNotificationService = $tripNotificationService;
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'from' => 'required|string',
            'to' => 'required|string',
            'departure_time' => 'required|date',
            'price' => 'required|numeric',
            'available_seats' => 'required|integer',
        ]);

        $trip = Trip::create([
            'driver_id' => Auth::id(),
            'from' => $validated['from'],
            'to' => $validated['to'],
            'departure_time' => $validated['departure_time'],
            'price' => $validated['price'],
            'available_seats' => $validated['available_seats'],
        ]);

        // Отправляем уведомление о новой поездке
        $this->tripNotificationService->notifyTripCreated($trip);

        return response()->json($trip, 201);
    }

    public function book(Request $request, Trip $trip)
    {
        if ($trip->available_seats <= 0) {
            return response()->json(['message' => 'Нет доступных мест'], 400);
        }

        $trip->update([
            'available_seats' => $trip->available_seats - 1,
        ]);

        // Отправляем уведомление о бронировании
        $this->tripNotificationService->notifyTripBooked($trip, Auth::user());

        return response()->json(['message' => 'Место успешно забронировано']);
    }

    public function cancel(Request $request, Trip $trip)
    {
        if ($trip->driver_id !== Auth::id()) {
            return response()->json(['message' => 'У вас нет прав для отмены этой поездки'], 403);
        }

        $trip->delete();

        // Отправляем уведомление об отмене поездки
        $this->tripNotificationService->notifyTripCancelled($trip, Auth::user());

        return response()->json(['message' => 'Поездка успешно отменена']);
    }

    public function complete(Request $request, Trip $trip)
    {
        if ($trip->driver_id !== Auth::id()) {
            return response()->json(['message' => 'У вас нет прав для завершения этой поездки'], 403);
        }

        $trip->update([
            'status' => 'completed',
        ]);

        // Отправляем уведомление о завершении поездки
        $this->tripNotificationService->notifyTripCompleted($trip);

        return response()->json(['message' => 'Поездка успешно завершена']);
    }
} 