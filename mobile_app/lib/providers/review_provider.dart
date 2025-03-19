import 'package:flutter/foundation.dart';
import 'package:letsgo/services/review_service.dart';
import 'package:letsgo/models/review.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  final List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;
  double _userRating = 0.0;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get userRating => _userRating;

  Future<void> loadTripReviews(String tripId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews.clear();
      _reviews.addAll(await _reviewService.getTripReviews(tripId, token));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserReviews(String userId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews.clear();
      _reviews.addAll(await _reviewService.getUserReviews(userId, token));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReview({
    required String tripId,
    required String reviewerId,
    required String reviewedId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final review = await _reviewService.createReview(
        tripId: tripId,
        reviewerId: reviewerId,
        reviewedId: reviewedId,
        rating: rating,
        comment: comment,
        token: token,
      );
      _reviews.add(review);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserRating(String userId, String token) async {
    try {
      _userRating = await _reviewService.getUserRating(userId, token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 