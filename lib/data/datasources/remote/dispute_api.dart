import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../local/local_storage.dart';
import '../../models/dispute_model.dart';

class DisputeApi {
  DisputeApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;
  final LocalStorage _storage = LocalStorage();

  Future<List<Dispute>> listDisputes() async {
    final dio = await _dioFuture;
    final response = await dio.get(
      ApiConstants.disputes,
      options: await _authOptions(),
    );
    final map = _unwrapMap(response.data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => Dispute.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Dispute> getDisputeById(String id) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.disputes}/$id',
      options: await _authOptions(),
    );
    final map = _unwrapMap(response.data);
    final disputeMap = _extractDispute(map);
    return Dispute.fromJson(disputeMap);
  }

  Future<Dispute> createDispute({
    required String serviceRequestId,
    required String reason,
    required String description,
    required String requestedResolution,
    List<XFile> media = const [],
  }) async {
    final dio = await _dioFuture;
    final payload = {
      'serviceRequestId': serviceRequestId,
      'reason': reason,
      'description': description,
      'requestedResolution': requestedResolution,
    };

    final response = await dio.post(
      ApiConstants.disputes,
      data: await _asFormData(payload, media),
      options: await _authOptions(),
    );

    final map = _unwrapMap(response.data);
    final disputeMap = _extractDispute(map);
    return Dispute.fromJson(disputeMap);
  }

  Future<Dispute> respondDispute({
    required String disputeId,
    required String decision,
    String? note,
    List<XFile> media = const [],
  }) async {
    final dio = await _dioFuture;
    final payload = {
      'decision': decision,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    final response = await dio.patch(
      '${ApiConstants.disputes}/$disputeId/respond',
      data: await _asFormData(payload, media),
      options: await _authOptions(),
    );

    final map = _unwrapMap(response.data);
    final disputeMap = _extractDispute(map);
    return Dispute.fromJson(disputeMap);
  }

  Future<FormData> _asFormData(
    Map<String, dynamic> payload,
    List<XFile> media,
  ) async {
    if (media.isEmpty) {
      return FormData.fromMap(payload);
    }
    return FormData.fromMap({
      ...payload,
      'media': [
        for (final file in media)
          await MultipartFile.fromFile(file.path, filename: file.name),
      ],
    });
  }

  Future<Options?> _authOptions() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> map) {
    final direct = map['data'] ?? map['disputes'] ?? map['items'];
    if (direct is List) {
      return direct;
    }

    if (direct is Map) {
      final nested = direct['disputes'] ?? direct['items'] ?? direct['data'];
      if (nested is List) {
        return nested;
      }
    }

    return const [];
  }

  Map<String, dynamic> _extractDispute(Map<String, dynamic> map) {
    final data = map['data'] ?? map['dispute'] ?? map['result'];
    if (data is Map<String, dynamic>) {
      if (data['dispute'] is Map) {
        return (data['dispute'] as Map).cast<String, dynamic>();
      }
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return map;
  }
}
