<?php

namespace App\Services;

use App\Models\Trip;
use App\Models\User;

class TripNotificationService
{
    protected $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    public function notifyTripCreated(Trip $trip)
    {
        // Получаем всех пассажиров, которые ищут поездки по этому маршруту
        $passengers = User::whereHas('searchPreferences', function ($query) use ($trip) {
            $query->where('from', 'like', '%' . $trip->from . '%')
                  ->where('to', 'like', '%' . $trip->to . '%')
                  ->where('departure_date', '>=', $trip->departure_time);
        })->get();

        foreach ($passengers as $passenger) {
            $this->firebaseService->sendNotificationToUser(
                $passenger->id,
                'Новая поездка по вашему маршруту',
                "Водитель {$trip->driver->name} создал поездку {$trip->from} → {$trip->to}",
                [
                    'type' => 'new_trip',
                    'trip_id' => $trip->id,
                    'from' => $trip->from,
                    'to' => $trip->to,
                    'departure_time' => $trip->departure_time,
                    'price' => $trip->price,
                ]
            );
        }
    }

    public function notifyTripBooked(Trip $trip, User $passenger)
    {
        // Уведомляем водителя
        $this->firebaseService->sendNotificationToUser(
            $trip->driver_id,
            'Новое бронирование',
            "Пассажир {$passenger->name} забронировал место в вашей поездке",
            [
                'type' => 'trip_booked',
                'trip_id' => $trip->id,
                'passenger_id' => $passenger->id,
                'passenger_name' => $passenger->name,
            ]
        );

        // Уведомляем пассажира
        $this->firebaseService->sendNotificationToUser(
            $passenger->id,
            'Поездка забронирована',
            "Вы успешно забронировали поездку {$trip->from} → {$trip->to}",
            [
                'type' => 'booking_confirmed',
                'trip_id' => $trip->id,
                'from' => $trip->from,
                'to' => $trip->to,
                'departure_time' => $trip->departure_time,
            ]
        );
    }

    public function notifyTripCancelled(Trip $trip, User $cancelledBy)
    {
        // Получаем всех пассажиров поездки
        $passengers = $trip->passengers;

        // Уведомляем всех пассажиров
        foreach ($passengers as $passenger) {
            $this->firebaseService->sendNotificationToUser(
                $passenger->id,
                'Поездка отменена',
                "Поездка {$trip->from} → {$trip->to} была отменена",
                [
                    'type' => 'trip_cancelled',
                    'trip_id' => $trip->id,
                    'from' => $trip->from,
                    'to' => $trip->to,
                    'cancelled_by' => $cancelledBy->name,
                ]
            );
        }

        // Если отменил водитель, уведомляем его
        if ($cancelledBy->id === $trip->driver_id) {
            $this->firebaseService->sendNotificationToUser(
                $trip->driver_id,
                'Поездка отменена',
                "Вы отменили поездку {$trip->from} → {$trip->to}",
                [
                    'type' => 'trip_cancelled',
                    'trip_id' => $trip->id,
                    'from' => $trip->from,
                    'to' => $trip->to,
                ]
            );
        }
    }

    public function notifyTripCompleted(Trip $trip)
    {
        // Уведомляем водителя
        $this->firebaseService->sendNotificationToUser(
            $trip->driver_id,
            'Поездка завершена',
            "Поездка {$trip->from} → {$trip->to} успешно завершена",
            [
                'type' => 'trip_completed',
                'trip_id' => $trip->id,
                'from' => $trip->from,
                'to' => $trip->to,
            ]
        );

        // Уведомляем всех пассажиров
        foreach ($trip->passengers as $passenger) {
            $this->firebaseService->sendNotificationToUser(
                $passenger->id,
                'Поездка завершена',
                "Поездка {$trip->from} → {$trip->to} успешно завершена",
                [
                    'type' => 'trip_completed',
                    'trip_id' => $trip->id,
                    'from' => $trip->from,
                    'to' => $trip->to,
                ]
            );
        }
    }
} 