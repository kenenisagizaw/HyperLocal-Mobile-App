import '../datasources/remote/booking_api.dart';
import '../models/booking_model.dart';

class BookingRepository {
  BookingRepository(this.api);

  final BookingApi api;

  Future<Booking> createBooking({
    required String serviceRequestId,
    required String quoteId,
    DateTime? scheduledAt,
    String? address,
  }) {
    return api.createBooking(
      serviceRequestId: serviceRequestId,
      quoteId: quoteId,
      scheduledAt: scheduledAt,
      address: address,
    );
  }

  Future<Booking> fetchBooking(String id) {
    return api.getBookingById(id);
  }

  Future<Booking?> updateBookingStatus({
    required String bookingId,
    required String status,
  }) {
    return api.updateStatus(bookingId: bookingId, status: status);
  }

  Future<Booking?> cancelBooking({
    required String bookingId,
    required String reason,
  }) {
    return api.cancelBooking(bookingId: bookingId, reason: reason);
  }

  Future<List<dynamic>> fetchAvailableSlots({
    String? providerId,
    String? serviceId,
    DateTime? date,
  }) {
    return api.getAvailableSlots(
      providerId: providerId,
      serviceId: serviceId,
      date: date,
    );
  }

  Future<List<Booking>> fetchMyBookings({
    String? status,
    int? take,
    int? skip,
  }) {
    return api.getMyBookings(status: status, take: take, skip: skip);
  }
}
