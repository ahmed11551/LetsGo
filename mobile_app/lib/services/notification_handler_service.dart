import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:letsgo/models/trip.dart';
import 'package:letsgo/screens/trip/trip_details_screen.dart';

class NotificationHandlerService {
  static final NotificationHandlerService _instance = NotificationHandlerService._internal();
  factory NotificationHandlerService() => _instance;
  NotificationHandlerService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void handleNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'new_trip':
        _handleNewTrip(data);
        break;
      case 'trip_booked':
        _handleTripBooked(data);
        break;
      case 'booking_confirmed':
        _handleBookingConfirmed(data);
        break;
      case 'trip_cancelled':
        _handleTripCancelled(data);
        break;
      case 'trip_completed':
        _handleTripCompleted(data);
        break;
    }
  }

  void _handleNewTrip(Map<String, dynamic> data) {
    final trip = Trip(
      id: data['trip_id'],
      driverId: data['driver_id'],
      from: data['from'],
      to: data['to'],
      departureTime: DateTime.parse(data['departure_time']),
      price: data['price'],
      availableSeats: data['available_seats'],
    );

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(trip: trip),
      ),
    );
  }

  void _handleTripBooked(Map<String, dynamic> data) {
    final trip = Trip(
      id: data['trip_id'],
      driverId: data['driver_id'],
      from: data['from'],
      to: data['to'],
      departureTime: DateTime.parse(data['departure_time']),
      price: data['price'],
      availableSeats: data['available_seats'],
    );

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(trip: trip),
      ),
    );
  }

  void _handleBookingConfirmed(Map<String, dynamic> data) {
    final trip = Trip(
      id: data['trip_id'],
      driverId: data['driver_id'],
      from: data['from'],
      to: data['to'],
      departureTime: DateTime.parse(data['departure_time']),
      price: data['price'],
      availableSeats: data['available_seats'],
    );

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(trip: trip),
      ),
    );
  }

  void _handleTripCancelled(Map<String, dynamic> data) {
    // Показываем диалог с информацией об отмене поездки
    navigatorKey.currentState?.showDialog(
      builder: (context) => AlertDialog(
        title: const Text('Поездка отменена'),
        content: Text(
          'Поездка ${data['from']} → ${data['to']} была отменена${data['cancelled_by'] != null ? ' пользователем ${data['cancelled_by']}' : ''}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleTripCompleted(Map<String, dynamic> data) {
    // Показываем диалог с информацией о завершении поездки
    navigatorKey.currentState?.showDialog(
      builder: (context) => AlertDialog(
        title: const Text('Поездка завершена'),
        content: Text(
          'Поездка ${data['from']} → ${data['to']} успешно завершена.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 