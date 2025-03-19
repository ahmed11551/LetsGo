import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:letsgo/services/notification_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([FirebaseMessaging, FlutterLocalNotificationsPlugin, http.Client])
import 'notification_service_test.mocks.dart';

void main() {
  late NotificationService service;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotifications;
  late MockClient mockHttpClient;

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockLocalNotifications = MockFlutterLocalNotificationsPlugin();
    mockHttpClient = MockClient();

    service = NotificationService();
  });

  group('NotificationService', () {
    test('should initialize notifications', () async {
      when(mockFirebaseMessaging.requestPermission()).thenAnswer((_) async => NotificationSettings(
        authorizationStatus: AuthorizationStatus.authorized,
        alert: true,
        badge: true,
        sound: true,
      ));

      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => 'test_token');

      await service.initialize();

      verify(mockFirebaseMessaging.requestPermission()).called(1);
      verify(mockFirebaseMessaging.getToken()).called(1);
      verify(mockLocalNotifications.initialize(any)).called(1);
    });

    test('should register device', () async {
      when(mockHttpClient.post(
        Uri.parse('http://localhost:8000/api/notifications/register'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "success"}', 200));

      await service.registerDevice('user123', 'device_token');

      verify(mockHttpClient.post(
        Uri.parse('http://localhost:8000/api/notifications/register'),
        headers: {'Content-Type': 'application/json'},
        body: '{"user_id":"user123","device_token":"device_token"}',
      )).called(1);
    });

    test('should unregister device', () async {
      when(mockHttpClient.post(
        Uri.parse('http://localhost:8000/api/notifications/unregister'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "success"}', 200));

      await service.unregisterDevice('user123');

      verify(mockHttpClient.post(
        Uri.parse('http://localhost:8000/api/notifications/unregister'),
        headers: {'Content-Type': 'application/json'},
        body: '{"user_id":"user123"}',
      )).called(1);
    });

    test('should handle foreground message', () async {
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Title',
          body: 'Test Body',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await service._handleForegroundMessage(message);

      verify(mockLocalNotifications.show(
        any,
        'Test Title',
        'Test Body',
        any,
        payload: message.data.toString(),
      )).called(1);
    });

    test('should handle message opened app', () {
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Test Title',
          body: 'Test Body',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      service._handleMessageOpenedApp(message);

      // Проверяем, что обработчик уведомлений был вызван
      verify(service._handler.handleNotification(message)).called(1);
    });

    test('should show local notification', () async {
      await service._showLocalNotification(
        title: 'Test Title',
        body: 'Test Body',
        payload: 'test_payload',
      );

      verify(mockLocalNotifications.show(
        any,
        'Test Title',
        'Test Body',
        any,
        payload: 'test_payload',
      )).called(1);
    });
  });
} 