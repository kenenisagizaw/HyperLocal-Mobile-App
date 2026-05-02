import '../datasources/remote/dispute_api.dart';
import '../models/dispute_model.dart';
import 'package:image_picker/image_picker.dart';

class DisputeRepository {
  DisputeRepository(this.api);

  final DisputeApi api;

  Future<List<Dispute>> fetchDisputes() {
    return api.listDisputes();
  }

  Future<Dispute> fetchDisputeById(String id) {
    return api.getDisputeById(id);
  }

  Future<Dispute> createDispute({
    required String serviceRequestId,
    required String reason,
    required String description,
    required String requestedResolution,
    List<XFile> media = const [],
  }) {
    return api.createDispute(
      serviceRequestId: serviceRequestId,
      reason: reason,
      description: description,
      requestedResolution: requestedResolution,
      media: media,
    );
  }

  Future<Dispute> respondDispute({
    required String disputeId,
    required String decision,
    String? note,
    List<XFile> media = const [],
  }) {
    return api.respondDispute(
      disputeId: disputeId,
      decision: decision,
      note: note,
      media: media,
    );
  }
}
