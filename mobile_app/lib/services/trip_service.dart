import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:letsgo/models/trip.dart';
import 'package:letsgo/providers/auth_provider.dart';

class TripService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<List<Trip>> searchTrips({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/search?from=$from&to=$to&date=${date.toIso8601String()}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Trip.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при поиске поездок');
    }
  }

  Future<Trip> createTrip({
    required String from,
    required String to,
    required DateTime departureTime,
    required double price,
    required int totalSeats,
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'from': from,
        'to': to,
        'departure_time': departureTime.toIso8601String(),
        'price': price,
        'total_seats': totalSeats,
        'from_lat': fromLat,
        'from_lng': fromLng,
        'to_lat': toLat,
        'to_lng': toLng,
      }),
    );

    if (response.statusCode == 201) {
      return Trip.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка при создании поездки');
    }
  }

  Future<void> bookTrip(String tripId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/book'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при бронировании поездки');
    }
  }

  Future<List<Trip>> getMyTrips(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Trip.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении списка поездок');
    }
  }

  Future<void> cancelTrip(String tripId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при отмене поездки');
    }
  }
} 