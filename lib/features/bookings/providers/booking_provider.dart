import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/error_utils.dart';
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

  Future<List<Booking>> loadMyBookings({
    String? status,
    int? take,
    int? skip,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final bookings = await repository.fetchMyBookings(
        status: status,
        take: take,
        skip: skip,
      );
      for (final booking in bookings) {
        _bookings[booking.id] = booking;
      }
      return bookings;
    } on DioException catch (error) {
      _setError(error);
      return const [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Booking>> loadMyBookingsAllStatuses({
    int? take,
    int? skip,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final results = <Booking>[];
      for (final status in BookingStatus.values) {
        final bookings = await repository.fetchMyBookings(
          status: _statusToApi(status),
          take: take,
          skip: skip,
        );
        results.addAll(bookings);
      }
      for (final booking in results) {
        _bookings[booking.id] = booking;
      }
      return results;
    } on DioException catch (error) {
      _setError(error);
      return const [];
    } finally {
      _setLoading(false);
    }
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
    print('DEBUG: Loading booking with ID: $id');
    _setLoading(true);
    _clearErrors();
    try {
      final booking = await repository.fetchBooking(id);
      print('DEBUG: Successfully loaded booking: ${booking.id}');
      _bookings[booking.id] = booking;
      return booking;
    } on DioException catch (error) {
      print(
        'DEBUG: Failed to load booking: ${error.response?.statusCode} - ${error.message}',
      );
      if (error.response?.statusCode == 404) {
        errorMessage =
            'Booking not found. The booking may have been deleted or the ID is incorrect.';
      } else {
        _setError(error);
      }
      return null;
    } catch (error) {
      print('DEBUG: Unexpected error loading booking: $error');
      errorMessage = 'An unexpected error occurred while loading the booking.';
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

  void _handleBookingUpdated(Map<String, dynamic> data) {
    try {
      final payload = data['booking'] is Map
          ? (data['booking'] as Map).cast<String, dynamic>()
          : data;
      final booking = Booking.fromJson(payload);
      _bookings[booking.id] = booking;
      notifyListeners();
    } catch (error) {
      debugPrint('Error handling booking.updated event: $error');
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
    errorMessage = ErrorUtils.friendlyMessage(
      error,
      fallbackMessage: 'Something went wrong. Please try again.',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
