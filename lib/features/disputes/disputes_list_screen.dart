import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/dispute_model.dart';
import '../auth/providers/auth_provider.dart';
import 'dispute_detail_screen.dart';
import 'providers/dispute_provider.dart';

class DisputesListScreen extends StatefulWidget {
  const DisputesListScreen({super.key});

  @override
  State<DisputesListScreen> createState() => _DisputesListScreenState();
}

class _DisputesListScreenState extends State<DisputesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DisputeProvider>().loadDisputes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisputeProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final disputes = provider.disputes;

    return Scaffold(
      appBar: AppBar(title: const Text('Disputes')),
      body: provider.isLoading && disputes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && disputes.isEmpty
          ? _ErrorState(
              message: provider.errorMessage ?? 'Failed to load disputes.',
              onRetry: () => provider.loadDisputes(),
            )
          : disputes.isEmpty
          ? const _EmptyState()
          : RefreshIndicator(
              onRefresh: () => provider.loadDisputes(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: disputes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final dispute = disputes[index];
                  final title =
                      dispute.serviceRequest?.title ?? 'Service Request';
                  final needsResponse =
                      user != null &&
                      dispute.isOpen &&
                      !dispute.hasResponded(user.id);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DisputeDetailScreen(disputeId: dispute.id),
                        ),
                      );
                    },
                    child: Container(
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dispute.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatusPill(status: dispute.status),
                              if (needsResponse) const _ActionPill(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Needs response',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
      ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No disputes yet',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
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
