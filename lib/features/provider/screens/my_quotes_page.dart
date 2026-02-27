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
    final quotes = currentUser == null
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
            Icon(Icons.attach_money_rounded,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No quotes yet',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Your sent quotes will appear here',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(
                    name: customer?.name ?? 'Customer',
                    imagePath: customer?.profilePicture,
                    radius: 28,
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
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: request?.status == RequestStatus.accepted
                                    ? _primaryGreen.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request == null
                                    ? 'Unknown'
                                    : _getQuoteStatus(request.status),
                                style: TextStyle(
                                  color: request?.status ==
                                          RequestStatus.accepted
                                      ? _primaryGreen
                                      : Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.notes,
                          style: TextStyle(color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category_rounded,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              request?.category ?? 'Unknown',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              formatNotificationTime(q.createdAt),
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getQuoteStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
      case RequestStatus.quoted:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
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

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        request?.locationLat != null && request?.locationLng != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryBlue.withValues(alpha: 0.1),
                    _primaryGreen.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quote Amount',
                        style: TextStyle(color: Colors.black54),
                      ),
                      Text(
                        '\$${quote.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      formatNotificationTime(quote.createdAt),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(quote.notes, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (request != null) ...[
              const Text(
                'Request Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    DetailRow(
                      icon: Icons.work_outline_rounded,
                      label: 'Category',
                      value: request!.category,
                    ),
                    const SizedBox(height: 12),
                    DetailRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Status',
                      value: formatRequestStatus(request!.status),
                      valueColor: request!.status == RequestStatus.accepted
                          ? _primaryGreen
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DetailRow(
                      icon: Icons.place_rounded,
                      label: 'Location',
                      value: request!.location,
                    ),
                    const SizedBox(height: 12),
                    DetailRow(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: request!.description,
                    ),
                  ],
                ),
              ),
            ],
            if (hasLocation) ...[
              const SizedBox(height: 20),
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CustomerProfileCard(customer: customer),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
