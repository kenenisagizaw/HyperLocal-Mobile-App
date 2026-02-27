import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/quote_model.dart';
import '../../../data/models/service_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_directory_provider.dart';
import '../../customer/providers/quote_provider.dart';
import '../../customer/providers/request_provider.dart';
import '../utils/formatters.dart';
import '../widgets/customer_profile_widgets.dart';
import '../widgets/user_avatar.dart';

class MyQuotesPage extends StatefulWidget {
  const MyQuotesPage({super.key});

  @override
  State<MyQuotesPage> createState() => _MyQuotesPageState();
}

class _MyQuotesPageState extends State<MyQuotesPage> {
  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RequestProvider>().loadRequests();
      context.read<CustomerDirectoryProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final quoteProvider = context.watch<QuoteProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final customerDirectory = context.watch<CustomerDirectoryProvider>();

    final currentUser = authProvider.currentUser;
    final quotes =
        currentUser == null
              ? <Quote>[]
              : quoteProvider.quotes
                    .where((q) => q.providerId == currentUser.id)
                    .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.request_quote_rounded,
                size: 64,
                color: _textSecondary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No quotes yet',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your sent quotes will appear here',
              style: TextStyle(color: _textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final q = quotes[index];
        final request = requestProvider.requests
            .where((r) => r.id == q.requestId)
            .cast<ServiceRequest?>()
            .firstWhere((r) => r != null, orElse: () => null);
        final customer = request == null
            ? null
            : customerDirectory.getCustomerById(request.customerId);

        final status = request?.status;
        final statusConfig = _getStatusConfig(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _surfaceColor, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuoteDetailScreen(
                      quote: q,
                      request: request,
                      customer: customer,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    UserAvatar(
                      name: customer?.name ?? 'Customer',
                      imagePath: customer?.profilePicture,
                      radius: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '\$${q.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: _primaryBlue,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusConfig.backgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusConfig.label,
                                  style: TextStyle(
                                    color: statusConfig.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (q.notes.isNotEmpty) ...[
                            Text(
                              q.notes,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              _buildInfoChip(
                                icon: Icons.category_rounded,
                                label: request?.category ?? 'Unknown',
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                icon: Icons.access_time_rounded,
                                label: formatNotificationTime(q.createdAt),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(RequestStatus? status) {
    if (status == null) {
      return _StatusConfig(
        label: 'Unknown',
        backgroundColor: Colors.grey.shade100,
        textColor: Colors.grey.shade700,
      );
    }

    switch (status) {
      case RequestStatus.accepted:
        return _StatusConfig(
          label: 'Accepted',
          backgroundColor: _primaryGreen.withValues(alpha: 0.1),
          textColor: _primaryGreen,
        );
      case RequestStatus.pending:
      case RequestStatus.quoted:
        return _StatusConfig(
          label: 'Pending',
          backgroundColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
        );
      case RequestStatus.completed:
        return _StatusConfig(
          label: 'Completed',
          backgroundColor: _primaryBlue.withValues(alpha: 0.1),
          textColor: _primaryBlue,
        );
      case RequestStatus.cancelled:
        return _StatusConfig(
          label: 'Cancelled',
          backgroundColor: Colors.red.shade50,
          textColor: Colors.red.shade700,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class QuoteDetailScreen extends StatelessWidget {
  const QuoteDetailScreen({
    super.key,
    required this.quote,
    required this.request,
    required this.customer,
  });

  final Quote quote;
  final ServiceRequest? request;
  final UserModel? customer;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);
  static const _surfaceColor = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        request?.locationLat != null && request?.locationLng != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quote Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        shape: Border(bottom: BorderSide(color: _surfaceColor, width: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryBlue.withValues(alpha: 0.08),
                    _primaryGreen.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _surfaceColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${quote.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: _primaryBlue,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '.${quote.price.toStringAsFixed(2).split('.').last}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _primaryBlue.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _surfaceColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatNotificationTime(quote.createdAt),
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes Section
            _buildSection(
              title: 'Notes',
              icon: Icons.note_alt_rounded,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  quote.notes,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Request Details
            if (request != null) ...[
              _buildSection(
                title: 'Request Details',
                icon: Icons.assignment_rounded,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildDetailItem(
                        icon: Icons.work_outline_rounded,
                        label: 'Category',
                        value: request!.category,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      _buildDetailItem(
                        icon: Icons.info_outline_rounded,
                        label: 'Status',
                        value: _formatRequestStatus(request!.status),
                        valueColor: request!.status == RequestStatus.accepted
                            ? _primaryGreen
                            : request!.status == RequestStatus.cancelled
                            ? Colors.red.shade700
                            : _primaryBlue,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      _buildDetailItem(
                        icon: Icons.place_rounded,
                        label: 'Location',
                        value: request!.location,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                      ),
                      _buildDetailItem(
                        icon: Icons.description_outlined,
                        label: 'Description',
                        value: request!.description,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Map Section
            if (hasLocation) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: 'Service Location',
                icon: Icons.location_on_rounded,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _surfaceColor, width: 1.5),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        request!.locationLat!,
                        request!.locationLng!,
                      ),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.my_first_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              request!.locationLat!,
                              request!.locationLng!,
                            ),
                            width: 50,
                            height: 50,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: _primaryBlue,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Customer Section
            _buildSection(
              title: 'Customer',
              icon: Icons.person_outline_rounded,
              child: CustomerProfileCard(customer: customer),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: _primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? _textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRequestStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.quoted:
        return 'Quoted';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}
