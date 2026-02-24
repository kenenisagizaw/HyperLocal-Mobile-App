import '../../core/constants/enums.dart';

class ServiceRequest {
  final String id;
  final String customerId;
  final String description;
  final String category;
  final String location;
  final double? locationLat;
  final double? locationLng;
  final double budget;
  final List<String> photoPaths;
  final DateTime createdAt;
  RequestStatus status;

  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.description,
    required this.category,
    required this.location,
    this.locationLat,
    this.locationLng,
    required this.budget,
    this.photoPaths = const [],
    required this.createdAt,
    this.status = RequestStatus.pending,
  });
}
