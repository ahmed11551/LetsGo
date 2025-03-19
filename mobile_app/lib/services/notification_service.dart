import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:letsgo/services/notification_handler_service.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost:8000/api/notifications';
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final NotificationHandlerService _handler = NotificationHandlerService();

  Future<void> initialize() async {
    // Запрашиваем разрешение на уведомления
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Инициализируем локальные уведомления
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(initializationSettings);

    // Получаем токен FCM
    final token = await _fcm.getToken();
    print('FCM Token: $token');

    // Обрабатываем уведомления в фоновом режиме
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обрабатываем уведомления в активном режиме
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Обрабатываем нажатие на уведомление
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> registerDevice(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id' => userId,
          'device_token' => token,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при регистрации устройства');
      }
    } catch (e) {
      print('Ошибка при регистрации устройства: $e');
      rethrow;
    }
  }

  Future<void> unregisterDevice(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/unregister'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id' => userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при отмене регистрации устройства');
      }
    } catch (e) {
      print('Ошибка при отмене регистрации устройства: $e');
      rethrow;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Получено уведомление в активном режиме: ${message.notification?.title}');
    
    // Показываем локальное уведомление
    await _showLocalNotification(
      title: message.notification?.title ?? 'Новое уведомление',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // Обрабатываем уведомление
    _handler.handleNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Уведомление открыто: ${message.notification?.title}');
    _handler.handleNotification(message);
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'letsgo_channel',
      'LetsGo Notifications',
      channelDescription: 'Уведомления приложения LetsGo',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }
}

// Функция для обработки уведомлений в фоновом режиме
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Получено уведомление в фоновом режиме: ${message.notification?.title}');
  NotificationHandlerService().handleNotification(message);
} 