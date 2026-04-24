import '../../core/constants/enums.dart';

class ServiceRequest {
  final String id;
  final String customerId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String? city;
  final double? locationLat;
  final double? locationLng;
  final double? budget;
  final double? budgetMin;
  final double? budgetMax;
  final List<String> photoPaths;
  final DateTime createdAt;
  RequestStatus status;

  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.city,
    this.locationLat,
    this.locationLng,
    this.budget,
    this.budgetMin,
    this.budgetMax,
    this.photoPaths = const [],
    required this.createdAt,
    this.status = RequestStatus.pending,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status'];
    final status = _parseStatus(statusValue);
    final latValue = json['latitude'] ?? json['locationLat'] ?? json['lat'];
    final lngValue = json['longitude'] ?? json['locationLng'] ?? json['lng'];
    final budgetValue = json['budget'] ?? json['budgetMin'];
    final budgetMinValue = json['budgetMin'] ?? json['budget_min'];
    final budgetMaxValue = json['budgetMax'] ?? json['budget_max'];
    final imagesValue = json['images'] ?? json['photoPaths'] ?? json['photos'];

    return ServiceRequest(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      customerId:
          (json['customerId'] ??
                  json['userId'] ??
                  json['customer']?['id'] ??
                  json['customer']?['userId'] ??
                  json['requester']?['id'] ??
                  json['requester']?['userId'] ??
                  json['requestedBy']?['id'] ??
                  json['requestedBy']?['userId'] ??
                  json['user']?['id'] ??
                  json['user']?['userId'] ??
                  '')
              .toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['serviceCategory'] ?? json['category'] ?? '').toString(),
      location: (json['location'] ?? json['address'] ?? json['city'] ?? '')
          .toString(),
      city: (json['city'] ?? json['locationCity'] ?? json['addressCity'])
          ?.toString(),
      locationLat: latValue is num ? latValue.toDouble() : null,
      locationLng: lngValue is num ? lngValue.toDouble() : null,
      budget: budgetValue is num ? budgetValue.toDouble() : null,
      budgetMin: budgetMinValue is num ? budgetMinValue.toDouble() : null,
      budgetMax: budgetMaxValue is num ? budgetMaxValue.toDouble() : null,
      photoPaths: _parseImages(imagesValue),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'title': title,
      'description': description,
      'serviceCategory': category,
      'location': location,
      if (city != null) 'city': city,
      'latitude': locationLat,
      'longitude': locationLng,
      'budget': budget,
      if (budgetMin != null) 'budgetMin': budgetMin,
      if (budgetMax != null) 'budgetMax': budgetMax,
      'images': photoPaths,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name.toUpperCase(),
    };
  }

  static RequestStatus _parseStatus(dynamic value) {
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'open' || normalized == 'pending') {
        return RequestStatus.pending;
      }
      if (normalized == 'quoted') {
        return RequestStatus.quoted;
      }
      if (normalized == 'in_progress' || normalized == 'accepted') {
        return RequestStatus.accepted;
      }
      if (normalized == 'completed') {
        return RequestStatus.completed;
      }
      if (normalized == 'cancelled' || normalized == 'canceled') {
        return RequestStatus.cancelled;
      }
    }
    if (value is int && value >= 0 && value < RequestStatus.values.length) {
      return RequestStatus.values[value];
    }
    return RequestStatus.pending;
  }

  static List<String> _parseImages(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
