import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:letsgo/models/review.dart';

class ReviewService {
  static const String baseUrl = 'http://localhost:8000/api/reviews';

  Future<List<Review>> getTripReviews(String tripId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trip/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении отзывов');
    }
  }

  Future<List<Review>> getUserReviews(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка при получении отзывов пользователя');
    }
  }

  Future<Review> createReview({
    required String tripId,
    required String reviewerId,
    required String reviewedId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'trip_id': tripId,
        'reviewer_id': reviewerId,
        'reviewed_id': reviewedId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      return Review.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка при создании отзыва');
    }
  }

  Future<double> getUserRating(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rating/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['rating'].toDouble();
    } else {
      throw Exception('Ошибка при получении рейтинга пользователя');
    }
  }
} 