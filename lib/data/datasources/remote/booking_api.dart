import 'package:dio/dio.dart';

// Deep Blue: Core constants and API client imports
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../models/booking_model.dart';
// Deep Green: Local storage and models
import '../local/local_storage.dart';

// Deep Blue: Main API class for booking operations
class BookingApi {
  BookingApi() : _dioFuture = ApiClient.create();

  // Deep Green: DIO client future for async initialization
  final Future<Dio> _dioFuture;
  // Deep Blue: Local storage instance for token management
  final LocalStorage _storage = LocalStorage();

  // Deep Green: Create a new booking
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
      options: await _authOptions(),
    );
    return _parseBooking(response.data);
  }

  // Deep Blue: Retrieve booking by ID
  Future<Booking> getBookingById(String id) async {
    print('DEBUG: API call to get booking: ${ApiConstants.bookings}/$id');
    final dio = await _dioFuture;
    final authOptions = await _authOptions();
    if (authOptions == null) {
      print('DEBUG: No authentication token available');
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.bookings}/$id'),
        type: DioExceptionType.cancel,
        error: 'No authentication token available',
      );
    }
    final response = await dio.get(
      '${ApiConstants.bookings}/$id',
      options: authOptions,
    );
    print('DEBUG: API response status: ${response.statusCode}');
    print('DEBUG: API response data: ${response.data}');
    
    if (response.statusCode == 404) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.bookings}/$id'),
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Booking not found',
      );
    }
    
    return _parseBooking(response.data);
  }

  // Deep Green: Get user's bookings with optional filters
  Future<List<Booking>> getMyBookings({
    String? status,
    int? take,
    int? skip,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.bookingsMine,
      options: await _authOptions(),
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (take != null) 'take': take,
        if (skip != null) 'skip': skip,
      },
    );
    return _parseBookingList(response.data);
  }

  // Deep Blue: Update booking status
  Future<Booking?> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.patch(
      '${ApiConstants.bookings}/$bookingId/status',
      data: {'status': status},
      options: await _authOptions(),
    );
    return _tryParseBooking(response.data);
  }

  // Deep Green: Cancel an existing booking
  Future<Booking?> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.patch(
      '${ApiConstants.bookings}/$bookingId/cancel',
      data: {'reason': reason},
      options: await _authOptions(),
    );
    return _tryParseBooking(response.data);
  }

  // Deep Blue: Get available time slots
  Future<List<dynamic>> getAvailableSlots({
    String? providerId,
    String? serviceId,
    DateTime? date,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.bookingSlots,
      options: await _authOptions(),
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

  // Deep Green: Parse single booking from response
  Booking _parseBooking(dynamic data) {
    print('DEBUG: _parseBooking called with data: $data');
    final map = _unwrapMap(data);
    print('DEBUG: Unwrapped map: $map');
    final bookingMap = _extractBookingMap(map);
    print('DEBUG: Extracted booking map: $bookingMap');
    try {
      final booking = Booking.fromJson(bookingMap);
      print('DEBUG: Successfully parsed booking: ${booking.id}');
      return booking;
    } on ArgumentError catch (e) {
      print('DEBUG: ArgumentError parsing booking: $e');
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        error: 'Invalid booking data: ${e.message}',
      );
    } catch (e) {
      print('DEBUG: Error parsing booking: $e');
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        error: 'Failed to parse booking data: $e',
      );
    }
  }

  // Deep Blue: Try to parse booking, return null if fails
  Booking? _tryParseBooking(dynamic data) {
    final map = _unwrapMap(data);
    final bookingMap = _extractBookingMap(map, allowEmpty: true);
    if (bookingMap.isEmpty) {
      return null;
    }
    return Booking.fromJson(bookingMap);
  }

  // Deep Green: Extract booking map from nested response structure
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

  // Deep Blue: Extract list from various response formats
  List<dynamic> _extractList(Map<String, dynamic> map) {
    final direct =
        map['data'] ?? map['items'] ?? map['slots'] ?? map['bookings'];
    if (direct is List) {
      return direct;
    }
    if (direct is Map) {
      final nested =
          direct['bookings'] ??
          direct['items'] ??
          direct['slots'] ??
          direct['data'];
      if (nested is List) {
        return nested;
      }
    }
    return const [];
  }

  // Deep Green: Parse list of bookings from response
  List<Booking> _parseBookingList(dynamic data) {
    final map = _unwrapMap(data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => Booking.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  // Deep Blue: Unwrap response data to map
  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  // Deep Green: Prepare authentication headers
  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // Deep Blue: Format date for API requests
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
