import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/error_utils.dart';
import '../../../data/models/dispute_model.dart';
import '../../../data/repositories/dispute_repository.dart';

class DisputeProvider extends ChangeNotifier {
  DisputeProvider({required this.repository});

  final DisputeRepository repository;

  List<Dispute> _disputes = [];
  final Map<String, Dispute> _disputeById = {};
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  List<Dispute> get disputes => List.unmodifiable(_disputes);
  bool get isLoading => _isLoading;

  Dispute? getDispute(String id) => _disputeById[id];

  Future<void> loadDisputes() async {
    _setLoading(true);
    _clearErrors();
    try {
      final results = await repository.fetchDisputes();
      _disputes = results;
      for (final dispute in results) {
        _disputeById[dispute.id] = dispute;
      }
    } on DioException catch (error) {
      _setError(error);
      _disputes = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Dispute?> fetchDispute(String id) async {
    _setLoading(true);
    _clearErrors();
    try {
      final dispute = await repository.fetchDisputeById(id);
      _disputeById[dispute.id] = dispute;
      _upsertDispute(dispute);
      return dispute;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Dispute?> createDispute({
    required String serviceRequestId,
    required String reason,
    required String description,
    required String requestedResolution,
    List<XFile> media = const [],
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final dispute = await repository.createDispute(
        serviceRequestId: serviceRequestId,
        reason: reason,
        description: description,
        requestedResolution: requestedResolution,
        media: media,
      );
      _disputeById[dispute.id] = dispute;
      _upsertDispute(dispute);
      return dispute;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Dispute?> respondDispute({
    required String disputeId,
    required String decision,
    String? note,
    List<XFile> media = const [],
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final dispute = await repository.respondDispute(
        disputeId: disputeId,
        decision: decision,
        note: note,
        media: media,
      );
      _disputeById[dispute.id] = dispute;
      _upsertDispute(dispute);
      return dispute;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _upsertDispute(Dispute dispute) {
    final index = _disputes.indexWhere((d) => d.id == dispute.id);
    if (index >= 0) {
      _disputes[index] = dispute;
    } else {
      _disputes = [dispute, ..._disputes];
    }
    _disputeById[dispute.id] = dispute;
    notifyListeners();
  }

  void _handleDisputeUpdated(Map<String, dynamic> data) {
    try {
      final payload = data['dispute'] is Map
          ? (data['dispute'] as Map).cast<String, dynamic>()
          : data;
      _upsertDispute(Dispute.fromJson(payload));
    } catch (error) {
      debugPrint('Error handling dispute_update event: $error');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    errorMessage = null;
    lastStatusCode = null;
  }

  void _setError(DioException error) {
    lastStatusCode = error.response?.statusCode;
    errorMessage = ErrorUtils.friendlyMessage(
      error,
      fallbackMessage: 'Something went wrong. Please try again.',
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
