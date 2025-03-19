import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:letsgo/services/notification_handler_service.dart';
import 'package:letsgo/models/trip.dart';

void main() {
  late NotificationHandlerService handler;
  late NavigatorState navigatorState;

  setUp(() {
    handler = NotificationHandlerService();
    navigatorState = NavigatorState();
    handler.navigatorKey.currentState = navigatorState;
  });

  group('NotificationHandlerService', () {
    test('should handle new trip notification', () {
      final message = RemoteMessage(
        data: {
          'type': 'new_trip',
          'trip_id': '1',
          'driver_id': '2',
          'from': 'Москва',
          'to': 'Санкт-Петербург',
          'departure_time': '2024-03-20T10:00:00Z',
          'price': 1000,
          'available_seats': 3,
        },
      );

      handler.handleNotification(message);

      // Проверяем, что был вызван метод push с правильными параметрами
      expect(navigatorState.routes.length, 1);
      expect(navigatorState.routes.first.settings.name, '/trip_details');
    });

    test('should handle trip booked notification', () {
      final message = RemoteMessage(
        data: {
          'type': 'trip_booked',
          'trip_id': '1',
          'driver_id': '2',
          'from': 'Москва',
          'to': 'Санкт-Петербург',
          'departure_time': '2024-03-20T10:00:00Z',
          'price': 1000,
          'available_seats': 2,
        },
      );

      handler.handleNotification(message);

      expect(navigatorState.routes.length, 1);
      expect(navigatorState.routes.first.settings.name, '/trip_details');
    });

    test('should handle trip cancelled notification', () {
      final message = RemoteMessage(
        data: {
          'type': 'trip_cancelled',
          'from': 'Москва',
          'to': 'Санкт-Петербург',
          'cancelled_by': 'Водитель',
        },
      );

      handler.handleNotification(message);

      // Проверяем, что был показан диалог
      expect(find.text('Поездка отменена'), findsOneWidget);
      expect(find.text('Поездка Москва → Санкт-Петербург была отменена пользователем Водитель'), findsOneWidget);
    });

    test('should handle trip completed notification', () {
      final message = RemoteMessage(
        data: {
          'type': 'trip_completed',
          'from': 'Москва',
          'to': 'Санкт-Петербург',
        },
      );

      handler.handleNotification(message);

      // Проверяем, что был показан диалог
      expect(find.text('Поездка завершена'), findsOneWidget);
      expect(find.text('Поездка Москва → Санкт-Петербург успешно завершена.'), findsOneWidget);
    });

    test('should handle unknown notification type', () {
      final message = RemoteMessage(
        data: {
          'type': 'unknown_type',
        },
      );

      // Проверяем, что не возникает ошибок при неизвестном типе уведомления
      expect(() => handler.handleNotification(message), returnsNormally);
    });
  });
} 