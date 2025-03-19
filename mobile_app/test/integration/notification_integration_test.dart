import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:letsgo/services/notification_service.dart';
import 'package:letsgo/services/notification_handler_service.dart';
import 'package:letsgo/test/integration/test_server.dart';

void main() {
  late NotificationService notificationService;
  late NotificationHandlerService handlerService;

  setUpAll(() async {
    // Запускаем тестовый сервер
    await TestServer.start();
  });

  setUp(() {
    notificationService = NotificationService();
    handlerService = NotificationHandlerService();
  });

  tearDownAll(() async {
    // Очищаем тестовые данные
    await TestServer.cleanup();
  });

  group('Notification Integration Tests', () {
    test('should register device and receive notifications', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Отправляем тестовое уведомление
      await TestServer.sendTestNotification();

      // Проверяем, что уведомление было получено и обработано
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should receive new trip notification', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем тестовую поездку
      final trip = await TestServer.createTestTrip();

      // Проверяем, что уведомление о новой поездке было получено
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
      expect(handlerService.navigatorKey.currentState?.routes.first.settings.name, '/trip_details');
    });

    test('should handle notification in background', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления в фоновом режиме
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await FirebaseMessaging.onBackgroundMessage(message);

      // Проверяем, что уведомление было обработано
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification when app is opened from notification', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем открытие приложения из уведомления
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что уведомление было обработано
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should unregister device and stop receiving notifications', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Отменяем регистрацию устройства
      await notificationService.unregisterDevice('test_user_123');

      // Отправляем тестовое уведомление
      await TestServer.sendTestNotification();

      // Проверяем, что уведомление не было получено
      expect(handlerService.navigatorKey.currentState?.routes.length, 0);
    });

    test('should handle multiple notifications in sequence', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Отправляем несколько уведомлений подряд
      for (int i = 0; i < 3; i++) {
        await TestServer.sendTestNotification();
      }

      // Проверяем, что все уведомления были обработаны
      expect(handlerService.navigatorKey.currentState?.routes.length, 3);
    });

    test('should handle notification with invalid data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректными данными
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'invalid_type',
          'id': 'invalid_id',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало и уведомление было обработано
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification when server is unavailable', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем недоступность сервера
      TestServer.baseUrl = 'http://invalid-url:8000';

      // Отправляем тестовое уведомление
      await TestServer.sendTestNotification();

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 0);

      // Восстанавливаем корректный URL
      TestServer.baseUrl = 'http://localhost:8000';
    });

    test('should handle notification with missing data fields', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с отсутствующими полями
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with malformed JSON data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным JSON
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': '{invalid json}',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with very large payload', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем большой payload
      final largeData = Map<String, String>.fromIterable(
        List.generate(1000, (i) => 'key$i'),
        key: (k) => k,
        value: (v) => 'value' * 100,
      );

      // Эмулируем получение уведомления с большим payload
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: largeData,
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with special characters in data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления со специальными символами
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': '!@#$%^&*()_+{}[]|\\:;"\'<>,.?/~`',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with emoji in data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с эмодзи
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': '🚗 🚕 🚌 🚎 🚓 🚑 🚒 🚐 🚚 🚛 🚜 🚨 🚔 🚍 🚘 🚖 🚡 🚠 🚟 🚃',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with unicode characters in data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с Unicode символами
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': 'Привет, мир! 你好，世界！ Bonjour, le monde!',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with empty data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с пустыми данными
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {},
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with null values in data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с null значениями
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': null,
          'id': null,
          'data': null,
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with nested data structures', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления со сложной структурой данных
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': {
            'nested': {
              'array': [1, 2, 3],
              'object': {
                'key': 'value',
                'number': 42,
                'boolean': true,
              },
            },
          },
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with very long text in data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем длинный текст
      final longText = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 100;

      // Эмулируем получение уведомления с длинным текстом
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': longText,
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with binary data', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем бинарные данные
      final binaryData = List<int>.generate(100, (i) => i % 256);

      // Эмулируем получение уведомления с бинарными данными
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'data': binaryData.toString(),
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with circular references', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем объект с циклическими ссылками
      final circularData = {
        'type': 'test',
        'self': null,
      };
      circularData['self'] = circularData;

      // Эмулируем получение уведомления с циклическими ссылками
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: circularData,
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with deep nesting', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем глубоко вложенную структуру данных
      Map<String, dynamic> createNestedStructure(int depth) {
        if (depth <= 0) return {'value': 'leaf'};
        return {
          'type': 'test',
          'nested': createNestedStructure(depth - 1),
        };
      }

      final deepNestedData = createNestedStructure(10);

      // Эмулируем получение уведомления с глубокой вложенностью
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: deepNestedData,
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with mixed data types', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем данные со смешанными типами
      final mixedData = {
        'type': 'test',
        'string': 'text',
        'number': 42,
        'boolean': true,
        'null': null,
        'array': [1, 'two', true, null],
        'object': {
          'nested': {
            'string': 'nested text',
            'number': 3.14,
            'boolean': false,
            'array': [1, 2, 3],
            'object': {
              'key': 'value',
            },
          },
        },
      };

      // Эмулируем получение уведомления со смешанными типами данных
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: mixedData,
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with duplicate keys', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем данные с дублирующимися ключами
      final duplicateData = {
        'type': 'test',
        'type': 'duplicate',
        'data': {
          'key': 'value1',
          'key': 'value2',
        },
      };

      // Эмулируем получение уведомления с дублирующимися ключами
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: duplicateData,
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with non-string keys', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Создаем данные с нестроковыми ключами
      final nonStringData = {
        1: 'number key',
        true: 'boolean key',
        null: 'null key',
        const Object(): 'object key',
      };

      // Эмулируем получение уведомления с нестроковыми ключами
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: nonStringData,
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification object', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным объектом notification
      final message = RemoteMessage(
        notification: null,
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with missing notification fields', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с отсутствующими полями в notification
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: null,
          body: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid message ID', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным messageId
      final message = RemoteMessage(
        messageId: null,
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid timestamp', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным временем
      final message = RemoteMessage(
        sentTime: DateTime.fromMillisecondsSinceEpoch(-1),
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid priority', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным приоритетом
      final message = RemoteMessage(
        priority: -1,
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid ttl', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным TTL
      final message = RemoteMessage(
        ttl: -1,
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid collapse key', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным collapse key
      final message = RemoteMessage(
        collapseKey: null,
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid from field', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным полем from
      final message = RemoteMessage(
        from: null,
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification channel', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным каналом уведомлений
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification tag', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным тегом
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          tag: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification icon', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректной иконкой
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidSmallIcon: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification color', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным цветом
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidColor: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification sound', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным звуком
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidSound: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification ticker', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным тикером
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidTicker: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification visibility', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректной видимостью
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidVisibility: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification category', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректной категорией
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidCategory: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification actions', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректными действиями
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidActions: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification style', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным стилем
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidStyleInformation: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification priority', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным приоритетом
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidPriority: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification importance', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректной важностью
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidImportance: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification badge', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным значком
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          badge: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification subtitle', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным подзаголовком
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          subtitle: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification image', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным изображением
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidImageUrl: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });

    test('should handle notification with invalid notification click action', () async {
      // Регистрируем тестовое устройство
      await TestServer.registerTestDevice();

      // Инициализируем сервис уведомлений
      await notificationService.initialize();

      // Эмулируем получение уведомления с некорректным действием при нажатии
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Тестовое уведомление',
          body: 'Тестовое сообщение',
          androidChannelId: 'test_channel',
          androidClickAction: null,
        ),
        data: {
          'type': 'test',
          'id': '123',
        },
      );

      await notificationService._handleMessageOpenedApp(message);

      // Проверяем, что приложение не упало
      expect(handlerService.navigatorKey.currentState?.routes.length, 1);
    });
  });
} 