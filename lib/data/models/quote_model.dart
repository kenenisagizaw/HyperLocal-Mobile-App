import '../../core/constants/enums.dart';

class Quote {
  final String id;
  final String requestId;
  final String providerName;
  final double price;
  final String message;
  final int? estimatedTime;
  final String? providerId;
  final String? providerPhone;
  final String? providerLocation;
  final String? providerCity;
  final String? providerImage;
  final double rating;
  final DateTime createdAt;
  final QuoteStatus status;
  final int? estimatedDays;

  Quote({
    required this.id,
    required this.requestId,
    required this.providerName,
    required this.price,
    required this.message,
    this.estimatedTime,
    this.estimatedDays,
    this.providerId,
    this.providerPhone,
    this.providerLocation,
    this.providerCity,
    this.providerImage,
    this.status = QuoteStatus.pending,
    double? rating,
    DateTime? createdAt,
  }) : rating = rating ?? 4.5,
       createdAt = createdAt ?? DateTime.now();

  String get notes => message;

  factory Quote.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'];
    final provider = json['provider'];
    return Quote(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      requestId: (json['serviceRequestId'] ?? json['requestId'] ?? '')
          .toString(),
      providerName: (json['providerName'] ?? provider?['name'] ?? '')
          .toString(),
      price: _parseDouble(json['price'] ?? json['amount']),
      message: (json['message'] ?? json['notes'] ?? '').toString(),
      estimatedTime: _parseInt(json['estimatedTime'] ?? json['eta']),
      estimatedDays: _parseInt(json['estimatedDays']),
      providerId: _asString(
        provider?['id'] ?? provider?['userId'] ?? json['providerId'],
      ),
      providerPhone: _asString(
        json['providerPhone'] ?? provider?['phone'],
      ),
      providerLocation: _asString(
        json['providerLocation'] ?? provider?['location'],
      ),
      providerCity: _asString(provider?['city']),
      providerImage: _asString(
        json['providerImage'] ?? provider?['avatarUrl'] ?? provider?['profilePicture'],
      ),
      status: _parseStatus(statusValue),
      rating: _parseDouble(json['rating'], fallback: 4.5),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceRequestId': requestId,
      'providerName': providerName,
      'price': price,
      'message': message,
      'estimatedTime': estimatedTime,
      'estimatedDays': estimatedDays,
      'providerId': providerId,
      'providerPhone': providerPhone,
      'providerLocation': providerLocation,
      'providerCity': providerCity,
      'providerImage': providerImage,
      'status': status.name.toUpperCase(),
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static QuoteStatus _parseStatus(dynamic value) {
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'accepted') {
        return QuoteStatus.accepted;
      }
      if (normalized == 'withdrawn') {
        return QuoteStatus.withdrawn;
      }
      if (normalized == 'rejected') {
        return QuoteStatus.rejected;
      }
      return QuoteStatus.pending;
    }
    if (value is int && value >= 0 && value < QuoteStatus.values.length) {
      return QuoteStatus.values[value];
    }
    return QuoteStatus.pending;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static double _parseDouble(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final result = value.toString();
    return result.isEmpty ? null : result;
  }
}
