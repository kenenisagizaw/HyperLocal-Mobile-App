class ServiceRequest {
  final String id;
  final String description;
  final String category;
  final String location;
  final double budget;
  String status; // pending, quoted, booked, inProgress, completed, disputed

  ServiceRequest({
    required this.id,
    required this.description,
    required this.category,
    required this.location,
    required this.budget,
    this.status = 'pending',
  });
}
