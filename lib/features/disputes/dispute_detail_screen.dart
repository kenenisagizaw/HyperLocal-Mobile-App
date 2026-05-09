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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          'Dispute Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchDispute(widget.disputeId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(dispute: dispute),

              const SizedBox(height: 20),

              _ModernSection(
                title: 'Reason',
                icon: Icons.info_outline_rounded,
                child: Text(
                  dispute.reason,
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _ModernSection(
                title: 'Description',
                icon: Icons.description_outlined,
                child: Text(
                  dispute.description,
                  style: const TextStyle(
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _ModernSection(
                title: 'Requested Resolution',
                icon: Icons.gavel_rounded,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    disputeResolutionLabel(dispute.requestedResolution),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _MediaSection(
                title: 'Evidence',
                icon: Icons.photo_library_outlined,
                urls: dispute.evidenceMediaUrls,
              ),

              const SizedBox(height: 20),

              _DecisionSection(
                title: 'Customer Response',
                icon: Icons.person_outline_rounded,
                decision: dispute.customerDecision,
                note: dispute.customerNote,
                mediaUrls: dispute.customerResponseMediaUrls,
              ),

              const SizedBox(height: 16),

              _DecisionSection(
                title: 'Provider Response',
                icon: Icons.handyman_outlined,
                decision: dispute.providerDecision,
                note: dispute.providerNote,
                mediaUrls: dispute.providerResponseMediaUrls,
              ),

              if (canRespond) ...[
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Respond to Dispute',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 10),

          _StatusPill(status: dispute.status),
        ],
      ),
    );
  }
}

class _ModernSection extends StatelessWidget {
  const _ModernSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.title,
    required this.icon,
    required this.urls,
  });

  final String title;
  final IconData icon;
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return _ModernSection(
      title: title,
      icon: icon,
      child: urls.isEmpty
          ? Text(
              'No media uploaded',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urls.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final url = urls[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    resolveMediaUrl(url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({
    required this.title,
    required this.icon,
    required this.decision,
    required this.note,
    required this.mediaUrls,
  });

  final String title;
  final IconData icon;
  final DisputeDecision decision;
  final String? note;
  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    return _ModernSection(
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: _decisionColor(decision).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              disputeDecisionLabel(decision),
              style: TextStyle(
                color: _decisionColor(decision),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              note!,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],

          if (mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mediaUrls.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final url = mediaUrls[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    resolveMediaUrl(url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Color _decisionColor(DisputeDecision decision) {
    switch (decision) {
      case DisputeDecision.accept:
        return Colors.green;

      case DisputeDecision.reject:
        return Colors.red;

      case DisputeDecision.pending:
        return Colors.orange;

      case DisputeDecision.unknown:
        return Colors.grey;
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DisputeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        disputeStatusLabel(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
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
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red.shade400,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}