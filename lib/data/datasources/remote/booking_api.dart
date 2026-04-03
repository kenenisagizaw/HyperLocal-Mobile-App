import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../models/booking_model.dart';

class BookingApi {
  BookingApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;

  Future<Booking> createBooking({
    required String serviceRequestId,
    required String quoteId,
    DateTime? scheduledAt,
    String? address,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.post(
      ApiConstants.bookings,
      data: {
        'serviceRequestId': serviceRequestId,
        'quoteId': quoteId,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
    return _parseBooking(response.data);
  }

  Future<Booking> getBookingById(String id) async {
    final dio = await _dioFuture;
    final response = await dio.get('${ApiConstants.bookings}/$id');
    return _parseBooking(response.data);
  }

  Future<List<Booking>> getMyBookings({
    String? status,
    int? take,
    int? skip,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.bookings,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (take != null) 'take': take,
        if (skip != null) 'skip': skip,
      },
    );
    return _parseBookingList(response.data);
  }

  Future<Booking?> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.patch(
      '${ApiConstants.bookings}/$bookingId/status',
      data: {'status': status},
    );
    return _tryParseBooking(response.data);
  }

  Future<Booking?> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.patch(
      '${ApiConstants.bookings}/$bookingId/cancel',
      data: {'reason': reason},
    );
    return _tryParseBooking(response.data);
  }

  Future<List<dynamic>> getAvailableSlots({
    String? providerId,
    String? serviceId,
    DateTime? date,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.bookingSlots,
      queryParameters: {
        if (providerId != null) 'providerId': providerId,
        if (serviceId != null) 'serviceId': serviceId,
        if (date != null) 'date': _formatDate(date),
      },
    );
    final map = _unwrapMap(response.data);
    final list = _extractList(map);
    return list;
  }

  Booking _parseBooking(dynamic data) {
    final map = _unwrapMap(data);
    final bookingMap = _extractBookingMap(map);
    return Booking.fromJson(bookingMap);
  }

  Booking? _tryParseBooking(dynamic data) {
    final map = _unwrapMap(data);
    final bookingMap = _extractBookingMap(map, allowEmpty: true);
    if (bookingMap.isEmpty) {
      return null;
    }
    return Booking.fromJson(bookingMap);
  }

  Map<String, dynamic> _extractBookingMap(
    Map<String, dynamic> map, {
    bool allowEmpty = false,
  }) {
    final data = map['data'] ?? map['booking'] ?? map['result'];
    if (data is Map<String, dynamic>) {
      if (data['booking'] is Map) {
        return (data['booking'] as Map).cast<String, dynamic>();
      }
      return data;
    }
    return allowEmpty ? map : <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> map) {
    final direct = map['data'] ?? map['items'] ?? map['slots'];
    if (direct is List) {
      return direct;
    }
    if (direct is Map) {
      final nested = direct['items'] ?? direct['slots'] ?? direct['data'];
      if (nested is List) {
        return nested;
      }
    }
    return const [];
  }

  List<Booking> _parseBookingList(dynamic data) {
    final map = _unwrapMap(data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => Booking.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
