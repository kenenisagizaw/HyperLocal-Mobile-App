import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/dispute_model.dart';
import '../auth/providers/auth_provider.dart';
import 'dispute_respond_screen.dart';
import 'providers/dispute_provider.dart';

class DisputeDetailScreen extends StatefulWidget {
  const DisputeDetailScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DisputeProvider>().fetchDispute(widget.disputeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisputeProvider>();
    final dispute = provider.getDispute(widget.disputeId);
    final user = context.watch<AuthProvider>().currentUser;

    if (provider.isLoading && dispute == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (dispute == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dispute')),
        body: _ErrorState(
          message: provider.errorMessage ?? 'Dispute not found.',
          onRetry: () => provider.fetchDispute(widget.disputeId),
        ),
      );
    }

    final canRespond = user != null &&
        dispute.isOpen &&
        !dispute.hasResponded(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Dispute')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(dispute: dispute),
            const SizedBox(height: 16),
            _Section(title: 'Reason', child: Text(dispute.reason)),
            const SizedBox(height: 12),
            _Section(title: 'Description', child: Text(dispute.description)),
            const SizedBox(height: 12),
            _Section(
              title: 'Requested Resolution',
              child: Text(disputeResolutionLabel(dispute.requestedResolution)),
            ),
            const SizedBox(height: 16),
            _MediaSection(
              title: 'Evidence',
              urls: dispute.evidenceMediaUrls,
            ),
            const SizedBox(height: 16),
            _DecisionSection(
              title: 'Customer Decision',
              decision: dispute.customerDecision,
              note: dispute.customerNote,
              mediaUrls: dispute.customerResponseMediaUrls,
            ),
            const SizedBox(height: 12),
            _DecisionSection(
              title: 'Provider Decision',
              decision: dispute.providerDecision,
              note: dispute.providerNote,
              mediaUrls: dispute.providerResponseMediaUrls,
            ),
            if (canRespond) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisputeRespondScreen(
                          disputeId: dispute.id,
                        ),
                      ),
                    );
                  },
                  child: const Text('Respond'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.dispute});

  final Dispute dispute;

  @override
  Widget build(BuildContext context) {
    final title = dispute.serviceRequest?.title ?? 'Service Request';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _StatusPill(status: dispute.status),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({required this.title, required this.urls});

  final String title;
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (urls.isEmpty)
          Text('No media', style: TextStyle(color: Colors.grey.shade600))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: urls
                .map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolveMediaUrl(url),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({
    required this.title,
    required this.decision,
    required this.note,
    required this.mediaUrls,
  });

  final String title;
  final DisputeDecision decision;
  final String? note;
  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(disputeDecisionLabel(decision)),
        if (note != null && note!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(note!, style: TextStyle(color: Colors.grey.shade700)),
        ],
        if (mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mediaUrls
                .map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolveMediaUrl(url),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined, size: 18),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DisputeStatus status;

  @override
  Widget build(BuildContext context) {
    final label = disputeStatusLabel(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _statusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return Colors.orange;
      case DisputeStatus.mutualAccepted:
        return Colors.green;
      case DisputeStatus.rejected:
        return Colors.red;
      case DisputeStatus.resolved:
        return Colors.blue;
      case DisputeStatus.cancelled:
        return Colors.grey;
      case DisputeStatus.unknown:
        return Colors.black54;
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
