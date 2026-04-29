import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/resolved_address_text.dart';
import '../../../data/models/quote_model.dart';
import '../../../data/models/service_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookings/booking_detail_screen.dart';
import '../../bookings/providers/booking_provider.dart';
import '../../customer/providers/quote_provider.dart';
import '../../customer/providers/request_provider.dart';
import '../quote_sent_screen.dart';
import '../widgets/customer_profile_widgets.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.request,
    required this.customer,
    required this.providerUser,
  });

  final ServiceRequest request;
  final UserModel? customer;
  final UserModel? providerUser;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _estimatedTimeController =
      TextEditingController();

  ServiceRequest? _detailRequest;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _detailRequest = widget.request;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final requestProvider = context.read<RequestProvider>();
      context.read<QuoteProvider>().loadMyQuotes();
      context.read<BookingProvider>().loadMyBookingsAllStatuses();
      final refreshed = await requestProvider.fetchRequestById(
        widget.request.id,
      );
      if (!mounted || refreshed == null) return;
      setState(() {
        _detailRequest = _mergeRequest(_currentRequest, refreshed);
      });
    });
  }

  ServiceRequest get _currentRequest => _detailRequest ?? widget.request;

  ServiceRequest _mergeRequest(ServiceRequest base, ServiceRequest incoming) {
    return ServiceRequest(
      id: incoming.id.isNotEmpty ? incoming.id : base.id,
      customerId: incoming.customerId.isNotEmpty
          ? incoming.customerId
          : base.customerId,
      title: incoming.title.isNotEmpty ? incoming.title : base.title,
      description: incoming.description.isNotEmpty
          ? incoming.description
          : base.description,
      category: incoming.category.isNotEmpty ? incoming.category : base.category,
      location: incoming.location.isNotEmpty ? incoming.location : base.location,
      city: (incoming.city ?? '').isNotEmpty ? incoming.city : base.city,
      locationLat: incoming.locationLat ?? base.locationLat,
      locationLng: incoming.locationLng ?? base.locationLng,
      budget: incoming.budget ?? base.budget,
      budgetMin: incoming.budgetMin ?? base.budgetMin,
      budgetMax: incoming.budgetMax ?? base.budgetMax,
      photoPaths: incoming.photoPaths.isNotEmpty
          ? incoming.photoPaths
          : base.photoPaths,
      createdAt: incoming.createdAt,
      status: incoming.status,
    );
  }

  ServiceRequest? _findRequestFromProvider(
    RequestProvider requestProvider,
    String requestId,
  ) {
    for (final request in requestProvider.requests) {
      if (request.id == requestId) {
        return request;
      }
    }
    return null;
  }

  Quote? _findExistingQuote(
    QuoteProvider quoteProvider,
    String requestId,
    String? providerId,
  ) {
    final quotes = quoteProvider.getQuotesForRequest(requestId);
    for (final quote in quotes) {
      if (providerId == null || quote.providerId == null) {
        return quote;
      }
      if (quote.providerId == providerId) {
        return quote;
      }
    }
    return null;
  }

  Future<void> _submitQuote() async {
    final quoteProvider = context.read<QuoteProvider>();
    final requestProvider = context.read<RequestProvider>();
    final activeRequest = _currentRequest;
    final priceText = _priceController.text.trim();
    final notes = _notesController.text.trim();
    final estimatedText = _estimatedTimeController.text.trim();

    if (priceText.isEmpty || notes.isEmpty || estimatedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter price, message, and estimated time.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid price.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final estimatedTime = int.tryParse(estimatedText);
    if (estimatedTime == null || estimatedTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid estimated time.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (activeRequest.status == RequestStatus.accepted ||
        activeRequest.status == RequestStatus.completed ||
        activeRequest.status == RequestStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This request is not open for quotes.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final quote = await quoteProvider.submitQuote(
      serviceRequestId: activeRequest.id,
      price: price,
      message: notes,
      estimatedTime: estimatedTime,
    );

    if (quote == null) {
      final message = quoteProvider.errorMessage ?? 'Quote submission failed.';
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

    requestProvider.updateStatus(activeRequest.id, RequestStatus.quoted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Quote submitted successfully!'),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QuoteSentScreen(quote: quote)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestProvider = context.watch<RequestProvider>();
    final providerRequest = _findRequestFromProvider(
      requestProvider,
      _currentRequest.id,
    );
    final request = providerRequest == null
        ? _currentRequest
        : _mergeRequest(_currentRequest, providerRequest);
    final customer = widget.customer;
    final quoteProvider = context.watch<QuoteProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final hasLocation =
        request.locationLat != null && request.locationLng != null;
    final existingQuote = _findExistingQuote(
      quoteProvider,
      request.id,
      currentUser?.id,
    );
    final hasActiveQuote =
        existingQuote != null &&
        existingQuote.status != QuoteStatus.rejected &&
        existingQuote.status != QuoteStatus.withdrawn;
    final booking = bookingProvider.getBookingForRequest(request.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title.isEmpty ? request.category : request.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildMediaSection(request.photoPaths),
            const SizedBox(height: 16),
            _buildLocationSection(request),
            const SizedBox(height: 16),
            _buildBudgetSection(request),
            const SizedBox(height: 20),
            if (hasLocation) ...[
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
                      request.locationLat!,
                      request.locationLng!,
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
                            request.locationLat!,
                            request.locationLng!,
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
              const SizedBox(height: 20),
            ],
            const Text(
              'Customer Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CustomerProfileCard(
              customer: customer,
              customerId: request.customerId,
            ),
            const SizedBox(height: 20),
            const Text(
              'Send Quote',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (hasActiveQuote)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.mark_chat_read_rounded,
                      color: _primaryGreen,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      existingQuote.status == QuoteStatus.accepted
                          ? 'Quote accepted. Waiting for booking.'
                          : 'Quote sent. Please wait for the customer response.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingDetailScreen(bookingId: booking.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('View Booking'),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Your Price',
                        prefixText: '\$ ',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _estimatedTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estimated Time (hours)',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message / Details',
                        alignLabelWithHint: true,
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitQuote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Send Quote',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(List<String> paths) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (paths.isEmpty)
            Text('No photos', style: TextStyle(color: Colors.grey.shade600))
          else
            _buildPhotoGallery(paths),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ServiceRequest request) {
    final address = request.location.isEmpty
        ? 'Location not set'
        : request.location;
    final city = (request.city ?? '').isEmpty ? null : request.city;
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ResolvedAddressText(
            lat: request.locationLat,
            lng: request.locationLng,
            fallback: address,
            style: const TextStyle(fontSize: 14),
          ),
          if (city != null) ...[
            const SizedBox(height: 6),
            Text(
              city,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetSection(ServiceRequest request) {
    final min = request.budgetMin;
    final max = request.budgetMax;
    String label;
    if (min != null && max != null) {
      label = '\$${min.toStringAsFixed(0)} - \$${max.toStringAsFixed(0)}';
    } else if (min != null) {
      label = '\$${min.toStringAsFixed(0)}';
    } else if (max != null) {
      label = '\$${max.toStringAsFixed(0)}';
    } else if (request.budget != null) {
      label = '\$${request.budget!.toStringAsFixed(0)}';
    } else {
      label = 'Not set';
    }
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> paths) {
    return SizedBox(
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
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, this.label, this.child})
    : assert(label != null || child != null);

  final IconData icon;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Flexible(
            child: child ?? Text(label ?? '', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
