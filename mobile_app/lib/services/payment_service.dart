import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:letsgo/models/trip.dart';

class PaymentService {
  static const String baseUrl = 'http://localhost:8000/api/payments';

  Future<String> createPayment({
    required Trip trip,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'trip_id': trip.id,
        'amount': trip.price,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['payment_url'];
    } else {
      throw Exception('Ошибка при создании платежа');
    }
  }

  Future<bool> checkPaymentStatus({
    required String paymentId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/status/$paymentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } else {
      throw Exception('Ошибка при проверке статуса платежа');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Ошибка при получении истории платежей');
    }
  }
} 