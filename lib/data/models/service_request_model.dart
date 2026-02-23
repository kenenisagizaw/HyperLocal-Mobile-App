import '../../core/constants/enums.dart'; 

class ServiceRequest {
  final String id;
  final String description;
  final String category;
  final String location;
  final double budget;
  RequestStatus status; 

  ServiceRequest({
    required this.id,
    required this.description,
    required this.category,
    required this.location,
    required this.budget,
    this.status = RequestStatus.pending,
  });
}