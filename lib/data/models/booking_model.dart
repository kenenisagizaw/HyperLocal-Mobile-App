import '../../core/constants/enums.dart';

class Booking {
  final String id;
  final String serviceRequestId;
  final String quoteId;
  final String? customerId;
  final String? providerId;
  final String? address;
  final DateTime? scheduledAt;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.serviceRequestId,
    required this.quoteId,
    this.customerId,
    this.providerId,
    this.address,
    this.scheduledAt,
    this.status = BookingStatus.booked,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Booking.fromJson(Map<String, dynamic> json) {
    final serviceRequest = json['serviceRequest'] is Map
        ? json['serviceRequest'] as Map
        : null;
    return Booking(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      serviceRequestId: (json['serviceRequestId'] ?? json['requestId'] ?? '')
          .toString(),
      quoteId: (json['acceptedQuoteId'] ?? json['quoteId'] ?? '').toString(),
      customerId: _asString(
        json['customerId'] ??
            json['userId'] ??
            json['customer']?['id'] ??
            json['customer']?['userId'] ??
            json['user']?['id'] ??
            json['user']?['userId'],
      ),
      providerId: _asString(
        json['provider']?['id'] ??
            json['provider']?['userId'] ??
            json['providerId'],
      ),
      address: _asString(
        json['address'] ??
            json['location'] ??
            serviceRequest?['address'] ??
            serviceRequest?['location'],
      ),
      scheduledAt: _parseDateOrNull(
        json['scheduledAt'] ?? json['scheduledFor'] ?? json['startTime'],
      ),
      status: _parseStatus(json['status']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDateOrNull(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceRequestId': serviceRequestId,
      'quoteId': quoteId,
      'customerId': customerId,
      'providerId': providerId,
      'address': address,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'status': status.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static BookingStatus _parseStatus(dynamic value) {
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'booked') {
        return BookingStatus.booked;
      }
      if (normalized == 'in_progress' || normalized == 'inprogress') {
        return BookingStatus.inProgress;
      }
      if (normalized == 'completed') {
        return BookingStatus.completed;
      }
      if (normalized == 'cancelled' || normalized == 'canceled') {
        return BookingStatus.cancelled;
      }
    }
    if (value is int && value >= 0 && value < BookingStatus.values.length) {
      return BookingStatus.values[value];
    }
    return BookingStatus.booked;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final result = value.toString();
    return result.isEmpty ? null : result;
  }
}
