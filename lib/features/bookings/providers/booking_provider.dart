import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({required this.repository});

  final BookingRepository repository;

  final Map<String, Booking> _bookings = {};
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  bool get isLoading => _isLoading;
  List<Booking> get bookings => _bookings.values.toList();

  Booking? getBooking(String id) => _bookings[id];

  Booking? getBookingForRequest(String requestId) {
    for (final booking in _bookings.values) {
      if (booking.serviceRequestId == requestId) {
        return booking;
      }
    }
    return null;
  }

  Future<Booking?> createBooking({
    required String serviceRequestId,
    required String quoteId,
    DateTime? scheduledAt,
    String? address,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final booking = await repository.createBooking(
        serviceRequestId: serviceRequestId,
        quoteId: quoteId,
        scheduledAt: scheduledAt,
        address: address,
      );
      _bookings[booking.id] = booking;
      return booking;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Booking?> loadBooking(String id) async {
    _setLoading(true);
    _clearErrors();
    try {
      final booking = await repository.fetchBooking(id);
      _bookings[booking.id] = booking;
      return booking;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Booking?> updateStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final booking = await repository.updateBookingStatus(
        bookingId: bookingId,
        status: _statusToApi(status),
      );
      if (booking != null) {
        _bookings[booking.id] = booking;
      }
      return booking;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Booking?> cancel({
    required String bookingId,
    required String reason,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final booking = await repository.cancelBooking(
        bookingId: bookingId,
        reason: reason,
      );
      if (booking != null) {
        _bookings[booking.id] = booking;
      }
      return booking;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  String _statusToApi(BookingStatus status) {
    switch (status) {
      case BookingStatus.booked:
        return 'BOOKED';
      case BookingStatus.inProgress:
        return 'IN_PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    errorMessage = null;
    lastStatusCode = null;
  }

  void _setError(DioException error) {
    lastStatusCode = error.response?.statusCode;
    errorMessage = _extractErrorMessage(error);
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }
}
