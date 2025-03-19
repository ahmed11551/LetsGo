import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestServer {
  static const String baseUrl = 'http://localhost:8000';
  static const String testUserToken = 'test_token_123';
  static const String testDeviceToken = 'test_device_token_456';

  static Future<void> start() async {
    // Проверяем, что сервер доступен
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      if (response.statusCode != 200) {
        throw Exception('Сервер недоступен');
      }
    } catch (e) {
      throw Exception('Не удалось подключиться к тестовому серверу: $e');
    }
  }

  static Future<Map<String, dynamic>> createTestTrip() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/trips'),
      headers: {
        'Authorization': 'Bearer $testUserToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'from': 'Москва',
        'to': 'Санкт-Петербург',
        'departure_time': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'price': 1000,
        'available_seats': 3,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Ошибка при создании тестовой поездки: ${response.body}');
    }

    return json.decode(response.body);
  }

  static Future<void> registerTestDevice() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/register'),
      headers: {
        'Authorization': 'Bearer $testUserToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': 'test_user_123',
        'device_token': testDeviceToken,
        'platform': 'android',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при регистрации тестового устройства: ${response.body}');
    }
  }

  static Future<void> sendTestNotification() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications/test'),
      headers: {
        'Authorization': 'Bearer $testUserToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при отправке тестового уведомления: ${response.body}');
    }
  }

  static Future<void> cleanup() async {
    // Очищаем тестовые данные
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/notifications/unregister'),
        headers: {
          'Authorization': 'Bearer $testUserToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': 'test_user_123',
        }),
      );
    } catch (e) {
      print('Ошибка при очистке тестовых данных: $e');
    }
  }
} 