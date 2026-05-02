import '../../core/constants/api_constants.dart';

enum DisputeStatus {
  open,
  mutualAccepted,
  rejected,
  resolved,
  cancelled,
  unknown,
}

enum DisputeDecision { accept, reject, pending, unknown }

enum DisputeResolution { refund, release, partial, unknown }

class DisputeParticipant {
  const DisputeParticipant({required this.id, required this.name});

  final String id;
  final String name;

  factory DisputeParticipant.fromJson(Map<String, dynamic> json) {
    return DisputeParticipant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class DisputeServiceRequest {
  const DisputeServiceRequest({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  factory DisputeServiceRequest.fromJson(Map<String, dynamic> json) {
    return DisputeServiceRequest(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class Dispute {
  Dispute({
    required this.id,
    required this.serviceRequestId,
    required this.customerId,
    required this.providerId,
    required this.createdById,
    required this.reason,
    required this.description,
    required this.requestedResolution,
    required this.status,
    required this.customerDecision,
    required this.providerDecision,
    required this.evidenceMediaUrls,
    required this.customerResponseMediaUrls,
    required this.providerResponseMediaUrls,
    required this.createdAt,
    this.updatedAt,
    this.customerNote,
    this.providerNote,
    this.resolvedAt,
    this.serviceRequest,
    this.customer,
    this.provider,
  });

  final String id;
  final String serviceRequestId;
  final String customerId;
  final String providerId;
  final String createdById;
  final String reason;
  final String description;
  final DisputeResolution requestedResolution;
  final DisputeStatus status;
  final DisputeDecision customerDecision;
  final DisputeDecision providerDecision;
  final List<String> evidenceMediaUrls;
  final List<String> customerResponseMediaUrls;
  final List<String> providerResponseMediaUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? customerNote;
  final String? providerNote;
  final DisputeServiceRequest? serviceRequest;
  final DisputeParticipant? customer;
  final DisputeParticipant? provider;

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: (json['id'] ?? '').toString(),
      serviceRequestId: (json['serviceRequestId'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      providerId: (json['providerId'] ?? '').toString(),
      createdById: (json['createdById'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      requestedResolution: _parseResolution(json['requestedResolution']),
      status: _parseStatus(json['status']),
      customerDecision: _parseDecision(json['customerDecision']),
      providerDecision: _parseDecision(json['providerDecision']),
      evidenceMediaUrls: _parseUrls(json['evidenceMediaUrls']),
      customerResponseMediaUrls: _parseUrls(json['customerResponseMediaUrls']),
      providerResponseMediaUrls: _parseUrls(json['providerResponseMediaUrls']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      resolvedAt: _parseDate(json['resolvedAt']),
      customerNote: (json['customerNote'] ?? '').toString().isEmpty
          ? null
          : (json['customerNote'] ?? '').toString(),
      providerNote: (json['providerNote'] ?? '').toString().isEmpty
          ? null
          : (json['providerNote'] ?? '').toString(),
      serviceRequest: json['serviceRequest'] is Map
          ? DisputeServiceRequest.fromJson(
              (json['serviceRequest'] as Map).cast<String, dynamic>(),
            )
          : null,
      customer: json['customer'] is Map
          ? DisputeParticipant.fromJson(
              (json['customer'] as Map).cast<String, dynamic>(),
            )
          : null,
      provider: json['provider'] is Map
          ? DisputeParticipant.fromJson(
              (json['provider'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  bool get isOpen => status == DisputeStatus.open;

  bool hasResponded(String userId) {
    if (userId == customerId) {
      return customerDecision != DisputeDecision.pending;
    }
    if (userId == providerId) {
      return providerDecision != DisputeDecision.pending;
    }
    return false;
  }

  static DisputeStatus _parseStatus(dynamic value) {
    final normalized = (value ?? '').toString().toUpperCase();
    switch (normalized) {
      case 'OPEN':
        return DisputeStatus.open;
      case 'MUTUAL_ACCEPTED':
        return DisputeStatus.mutualAccepted;
      case 'REJECTED':
        return DisputeStatus.rejected;
      case 'RESOLVED':
        return DisputeStatus.resolved;
      case 'CANCELLED':
        return DisputeStatus.cancelled;
      default:
        return DisputeStatus.unknown;
    }
  }

  static DisputeDecision _parseDecision(dynamic value) {
    final normalized = (value ?? '').toString().toUpperCase();
    switch (normalized) {
      case 'ACCEPT':
        return DisputeDecision.accept;
      case 'REJECT':
        return DisputeDecision.reject;
      case 'PENDING':
        return DisputeDecision.pending;
      default:
        return DisputeDecision.unknown;
    }
  }

  static DisputeResolution _parseResolution(dynamic value) {
    final normalized = (value ?? '').toString().toUpperCase();
    switch (normalized) {
      case 'REFUND':
        return DisputeResolution.refund;
      case 'RELEASE':
        return DisputeResolution.release;
      case 'PARTIAL':
        return DisputeResolution.partial;
      default:
        return DisputeResolution.unknown;
    }
  }

  static List<String> _parseUrls(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

String resolveMediaUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/')) {
    return '${ApiConstants.baseUrl}$path';
  }
  return path;
}

String disputeStatusLabel(DisputeStatus status) {
  switch (status) {
    case DisputeStatus.open:
      return 'Open';
    case DisputeStatus.mutualAccepted:
      return 'Mutual Accepted';
    case DisputeStatus.rejected:
      return 'Rejected';
    case DisputeStatus.resolved:
      return 'Resolved';
    case DisputeStatus.cancelled:
      return 'Cancelled';
    default:
      return 'Unknown';
  }
}

String disputeResolutionLabel(DisputeResolution resolution) {
  switch (resolution) {
    case DisputeResolution.refund:
      return 'Refund';
    case DisputeResolution.release:
      return 'Release';
    case DisputeResolution.partial:
      return 'Partial';
    default:
      return 'Unknown';
  }
}

String disputeDecisionLabel(DisputeDecision decision) {
  switch (decision) {
    case DisputeDecision.accept:
      return 'Accept';
    case DisputeDecision.reject:
      return 'Reject';
    case DisputeDecision.pending:
      return 'Pending';
    default:
      return 'Unknown';
  }
}
