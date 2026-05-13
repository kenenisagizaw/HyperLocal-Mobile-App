import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/websocket_service.dart';
import '../../../data/models/dispute_model.dart';
import '../../../data/repositories/dispute_repository.dart';

class DisputeProvider extends ChangeNotifier {
  DisputeProvider({required this.repository}) {
    initializeWebSocket();
  }

  final DisputeRepository repository;
  final WebSocketService _webSocketService = WebSocketService();

  List<Dispute> _disputes = [];
  final Map<String, Dispute> _disputeById = {};
  StreamSubscription<WebSocketEvent>? _websocketSubscription;
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  List<Dispute> get disputes => List.unmodifiable(_disputes);
  bool get isLoading => _isLoading;

  Dispute? getDispute(String id) => _disputeById[id];

  void initializeWebSocket() {
    _websocketSubscription?.cancel();
    _websocketSubscription = _webSocketService.events.listen((event) {
      if (event.type == 'dispute_update') {
        _handleDisputeUpdated(event.data);
      }
    });
  }

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
    errorMessage = _extractErrorMessage(error);
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }

  @override
  void dispose() {
    _websocketSubscription?.cancel();
    super.dispose();
  }
}
