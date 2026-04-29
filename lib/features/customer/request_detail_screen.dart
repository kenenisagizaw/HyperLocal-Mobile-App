import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/widgets/resolved_address_text.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../bookings/booking_creation_screen.dart';
import '../bookings/booking_detail_screen.dart';
import '../bookings/providers/booking_provider.dart';
import '../customer/providers/provider_directory_provider.dart';
import '../messages/messages_screen.dart';
import '../provider/widgets/customer_profile_widgets.dart';
import '../provider/widgets/user_avatar.dart';
import 'providers/quote_provider.dart';
import 'providers/request_provider.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.request,
    this.initialQuotes = const [],
  });

  final ServiceRequest request;
  final List<Quote> initialQuotes;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final Set<String> _requestedProviderIds = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuoteProvider>().loadQuotesForRequest(widget.request.id);
      context.read<BookingProvider>().loadMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = context.watch<QuoteProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final providerDirectory = context.watch<ProviderDirectoryProvider>();

    final request = widget.request;
    final booking = bookingProvider.getBookingForRequest(request.id);
    final quotes = quoteProvider.getQuotesForRequest(request.id);
    final effectiveQuotes = quotes.isEmpty ? widget.initialQuotes : quotes;

    _prefetchProviders(providerDirectory, effectiveQuotes);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestSummaryCard(request),
                const SizedBox(height: 18),
                Text(
                  'Quotes (${effectiveQuotes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                if (quoteProvider.isLoading && effectiveQuotes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                  )
                else if (effectiveQuotes.isEmpty)
                  _buildEmptyQuotes()
                else
                  Column(
                    children: effectiveQuotes
                        .map(
                          (quote) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildQuoteCard(
                              context,
                              quote,
                              request: request,
                              booking: booking,
                              quoteProvider: quoteProvider,
                              requestProvider: requestProvider,
                              bookingProvider: bookingProvider,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _prefetchProviders(
    ProviderDirectoryProvider providerDirectory,
    List<Quote> quotes,
  ) {
    for (final quote in quotes) {
      final providerId = quote.providerId;
      if (providerId == null || providerId.isEmpty) {
        continue;
      }
      if (_requestedProviderIds.contains(providerId)) {
        continue;
      }
      final cached = providerDirectory.getProviderById(providerId);
      if (cached != null) {
        _requestedProviderIds.add(providerId);
        continue;
      }
      _requestedProviderIds.add(providerId);
      providerDirectory.fetchProviderById(providerId);
    }
  }

  Widget _buildRequestSummaryCard(ServiceRequest request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusPill(request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Category',
            value: request.category.isEmpty ? 'N/A' : request.category,
            icon: Icons.category_outlined,
          ),
          if (request.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildPhotoGallery(request.photoPaths),
          ],
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Location',
            value: request.location.isEmpty ? 'N/A' : request.location,
            icon: Icons.location_on_outlined,
            valueWidget: ResolvedAddressText(
              lat: request.locationLat,
              lng: request.locationLng,
              fallback: request.location.isEmpty ? 'N/A' : request.location,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Budget',
            value: request.budget == null
                ? 'Not set'
                : '\$${request.budget!.toStringAsFixed(2)}',
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            label: 'Created',
            value: _formatDate(request.createdAt),
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(
    BuildContext context,
    Quote quote, {
    required ServiceRequest request,
    required BookingProvider bookingProvider,
    required QuoteProvider quoteProvider,
    required RequestProvider requestProvider,
    required dynamic booking,
  }) {
    final providerDirectory = context.read<ProviderDirectoryProvider>();
    final provider = quote.providerId == null
        ? null
        : providerDirectory.getProviderById(quote.providerId!);
    final distanceLabel = formatDistanceKm(
      fromLat: request.locationLat,
      fromLng: request.locationLng,
      toLat: provider?.latitude,
      toLng: provider?.longitude,
    );
    final providerName = quote.providerName.isEmpty
        ? 'Service Provider'
        : quote.providerName;
    final providerCity = quote.providerCity;
    final requestLocked =
        request.status == RequestStatus.accepted ||
        request.status == RequestStatus.completed ||
        request.status == RequestStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: providerName,
                  imagePath: quote.providerImage,
                  radius: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      if (providerCity != null && providerCity.isNotEmpty)
                        Text(
                          providerCity,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${quote.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quote.message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (quote.estimatedDays != null)
              Text(
                'ETA: ${quote.estimatedDays} days',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )
            else if (quote.estimatedTime != null)
              Text(
                'ETA: ${quote.estimatedTime} hours',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            if (distanceLabel != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Distance: $distanceLabel',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: quote.providerId == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderProfileDetailScreen(
                              providerId: quote.providerId!,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.person_outline),
                label: const Text('View Provider Profile'),
              ),
            ),
            if (quote.providerId != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(
                          conversationId: null,
                          otherUserId: quote.providerId!,
                          otherUserName: providerName,
                          otherUser: null,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message Provider'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: quote.status == QuoteStatus.accepted
                  ? OutlinedButton.icon(
                      onPressed: () {
                        if (booking != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingDetailScreen(bookingId: booking.id),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingCreationScreen(
                              request: request,
                              quote: quote,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: Text(booking == null ? 'Schedule' : 'Booking'),
                    )
                  : requestLocked
                  ? (request.status == RequestStatus.accepted && booking != null
                        ? OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingDetailScreen(
                                    bookingId: booking.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: const Text('View Booking'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              request.status == RequestStatus.accepted
                                  ? 'Quote already accepted. Waiting for booking.'
                                  : 'Request closed.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                  : ElevatedButton(
                      onPressed: () async {
                        if (quote.status != QuoteStatus.pending) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Only pending quotes can be accepted.',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        final accepted = await quoteProvider.acceptQuote(
                          requestId: request.id,
                          quoteId: quote.id,
                        );

                        if (!accepted) {
                          final message =
                              quoteProvider.errorMessage ??
                              'Failed to accept quote.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        requestProvider.updateStatus(
                          request.id,
                          RequestStatus.accepted,
                        );

                        if (!mounted) return;

                        final existingBooking = bookingProvider
                            .getBookingForRequest(request.id);
                        if (existingBooking != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(
                                bookingId: existingBooking.id,
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingCreationScreen(
                              request: request,
                              quote: quote,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Accept'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuotes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.request_quote, color: Colors.blue.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No quotes yet. Providers will respond soon.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(RequestStatus status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange.shade600;
      case RequestStatus.quoted:
        return Colors.purple.shade600;
      case RequestStatus.accepted:
        return Colors.blue.shade600;
      case RequestStatus.completed:
        return Colors.green.shade600;
      case RequestStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  String _getStatusText(RequestStatus status) {
    return status
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _buildPhotoGallery(List<String> paths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final path = paths[index];
              final resolvedPath = _resolveMediaPath(path);
              final isRemote = _isRemotePath(path);
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  color: Colors.grey.shade100,
                  child: isRemote
                      ? Image.network(resolvedPath, fit: BoxFit.cover)
                      : Image.file(File(resolvedPath), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _resolveMediaPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '${ApiConstants.baseUrl}$path';
    }
    return path;
  }

  bool _isRemotePath(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('/');
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade50, Colors.green.shade50],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueWidget,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade600),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
        ),
        Expanded(
          flex: 3,
          child:
              valueWidget ??
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1E3A8A),
                ),
              ),
        ),
      ],
    );
  }
}
