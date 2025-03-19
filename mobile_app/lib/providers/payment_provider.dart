import 'package:flutter/foundation.dart';
import 'package:letsgo/services/payment_service.dart';
import 'package:letsgo/models/trip.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _paymentHistory = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get paymentHistory => _paymentHistory;

  Future<String> createPayment({
    required Trip trip,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paymentUrl = await _paymentService.createPayment(
        trip: trip,
        token: token,
      );
      return paymentUrl;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkPaymentStatus({
    required String paymentId,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isSuccess = await _paymentService.checkPaymentStatus(
        paymentId: paymentId,
        token: token,
      );
      return isSuccess;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPaymentHistory(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _paymentHistory = await _paymentService.getPaymentHistory(token);
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