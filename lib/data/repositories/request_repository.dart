import '../datasources/remote/request_api.dart';
import '../models/service_request_model.dart';

class RequestRepository {
  final RequestApi api;

  RequestRepository(this.api);

  Future<void> createRequest(ServiceRequest request) {
    return api.createRequest(request);
  }

  Future<List<ServiceRequest>> fetchRequests() {
    return api.getRequests();
  }
}
