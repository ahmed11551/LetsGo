import 'package:flutter/foundation.dart';
import 'package:letsgo/models/trip.dart';
import 'package:letsgo/services/trip_service.dart';
import 'package:letsgo/providers/auth_provider.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> searchTrips({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _tripService.searchTrips(
        from: from,
        to: to,
        date: date,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTrip({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final trip = await _tripService.createTrip(
        from: from,
        to: to,
        departureTime: departureTime,
        price: price,
        totalSeats: totalSeats,
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        token: token,
      );
      _trips.add(trip);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bookTrip(String tripId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.bookTrip(tripId, token);
      final index = _trips.indexWhere((trip) => trip.id == tripId);
      if (index != -1) {
        final trip = _trips[index];
        _trips[index] = Trip(
          id: trip.id,
          driverId: trip.driverId,
          driverName: trip.driverName,
          driverPhone: trip.driverPhone,
          from: trip.from,
          to: trip.to,
          departureTime: trip.departureTime,
          price: trip.price,
          totalSeats: trip.totalSeats,
          availableSeats: trip.availableSeats - 1,
          fromLat: trip.fromLat,
          fromLng: trip.fromLng,
          toLat: trip.toLat,
          toLng: trip.toLng,
          status: trip.status,
          createdAt: trip.createdAt,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getMyTrips(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _tripService.getMyTrips(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelTrip(String tripId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.cancelTrip(tripId, token);
      _trips.removeWhere((trip) => trip.id == tripId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 