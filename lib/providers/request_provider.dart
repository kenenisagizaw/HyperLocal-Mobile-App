import 'package:flutter/material.dart';
import '../data/models/service_request_model.dart';

class RequestProvider extends ChangeNotifier {
  List<ServiceRequest> requests = [
    ServiceRequest(
      id: '1',
      description: 'Fix leaking pipe',
      category: 'Plumbing',
      location: 'Bole',
      budget: 1500,
    ),
    ServiceRequest(
      id: '2',
      description: 'Paint living room',
      category: 'Painting',
      location: 'Kazanchis',
      budget: 2000,
    ),
  ];

  void addRequest(ServiceRequest request) {
    requests.add(request);
    notifyListeners();
  }

  void updateStatus(String requestId, String status) {
    final req = requests.firstWhere((r) => r.id == requestId);
    req.status = status;
    notifyListeners();
  }
}
