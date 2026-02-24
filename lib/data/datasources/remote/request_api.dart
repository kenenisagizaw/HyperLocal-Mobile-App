import '../../models/service_request_model.dart';
import '../../../core/constants/enums.dart';

class RequestApi {
  final List<ServiceRequest> _requests = [];

  RequestApi() {
    _requests.addAll([
      ServiceRequest(
        id: 'seed-1',
        customerId: '1',
        description: 'Fix leaking kitchen sink pipe',
        category: 'Plumbing',
        location: 'Bole',
        locationLat: null,
        locationLng: null,
        budget: 1200,
        photoPaths: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: RequestStatus.pending,
      ),
      ServiceRequest(
        id: 'seed-2',
        customerId: '1',
        description: 'Repaint living room walls',
        category: 'Painting',
        location: 'Kazanchis',
        locationLat: null,
        locationLng: null,
        budget: 2500,
        photoPaths: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: RequestStatus.quoted,
      ),
    ]);
  }

  Future<void> createRequest(ServiceRequest request) async {
    _requests.add(request);
  }

  Future<List<ServiceRequest>> getRequests() async {
    return _requests;
  }
}
