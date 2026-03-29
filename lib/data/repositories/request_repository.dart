import 'package:image_picker/image_picker.dart';

import '../datasources/remote/request_api.dart';
import '../models/service_request_model.dart';

class RequestRepository {
  final RequestApi api;

  RequestRepository(this.api);

  Future<ServiceRequest> createRequest({
    required String title,
    required String description,
    required String category,
    required String location,
    double? budget,
    double? latitude,
    double? longitude,
    DateTime? preferredDate,
    DateTime? expiresAt,
    List<XFile> images = const [],
  }) {
    return api.createRequest(
      title: title,
      description: description,
      category: category,
      location: location,
      budget: budget,
      latitude: latitude,
      longitude: longitude,
      preferredDate: preferredDate,
      expiresAt: expiresAt,
      images: images,
    );
  }

  Future<List<ServiceRequest>> fetchRequests({
    String? category,
    String? city,
    String? status,
    int? take,
    int? skip,
  }) {
    return api.getRequests(
      category: category,
      city: city,
      status: status,
      take: take,
      skip: skip,
    );
  }

  Future<List<ServiceRequest>> fetchMyRequests() {
    return api.getMyRequests();
  }

  Future<ServiceRequest> fetchRequestById(String id) {
    return api.getRequestById(id);
  }
}
