import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// Deep Blue: Core constants and models
import '../../core/constants/api_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/widgets/resolved_address_text.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/user_model.dart';
// Deep Green: Auth and customer providers
import '../auth/providers/auth_provider.dart';
import '../customer/providers/customer_directory_provider.dart';
import '../customer/providers/provider_directory_provider.dart';
import '../customer/providers/quote_provider.dart';
import '../customer/providers/request_provider.dart';
import '../disputes/dispute_create_screen.dart';
// Deep Blue: Messages and reviews screens
import '../messages/messages_screen.dart';
import '../payments/payment_screen.dart';
import '../provider/widgets/customer_profile_widgets.dart';
import '../provider/widgets/user_avatar.dart';
import '../reviews/review_screen.dart';
// Deep Green: Booking provider
import 'providers/booking_provider.dart';

// Deep Blue: Main booking detail screen
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

// Deep Green: State management for booking details
class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isSharingLocation = false;
  String? _requestedProviderId;
  String? _requestedCustomerId;
  bool _requestedQuotes = false;
  int _retryCount = 0;
  bool _isLoadingCustomerProfile = false;

  // Deep Blue: Initialize and load booking on mount
  @override
  void initState() {
    super.initState();
    print(
      'DEBUG: BookingDetailScreen initialized with bookingId: ${widget.bookingId}',
    );

    // Validate booking ID
    if (widget.bookingId.isEmpty || widget.bookingId.length < 3) {
      print('DEBUG: Invalid booking ID detected: ${widget.bookingId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid booking ID provided'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Check if booking is already in cache first
      final bookingProvider = context.read<BookingProvider>();
      final existingBooking = bookingProvider.getBooking(widget.bookingId);

      if (existingBooking != null) {
        print('DEBUG: Booking found in cache: ${existingBooking.id}');
        // No need to load from API, booking is already available
        return;
      }

      print(
        'DEBUG: Booking not in cache, calling loadBooking for bookingId: ${widget.bookingId}',
      );
      bookingProvider.loadBooking(widget.bookingId);
    });
  }

  // Deep Green: Main build method with all sections
  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();
    final providerDirectory = context.watch<ProviderDirectoryProvider>();
    final customerDirectory = context.watch<CustomerDirectoryProvider>();

    final booking = bookingProvider.getBooking(widget.bookingId);
    final user = authProvider.currentUser;

    print('DEBUG: Build method - bookingId: ${widget.bookingId}');
    print('DEBUG: Build method - booking: $booking');
    print('DEBUG: Build method - isLoading: ${bookingProvider.isLoading}');
    print(
      'DEBUG: Build method - errorMessage: ${bookingProvider.errorMessage}',
    );
    print(
      'DEBUG: Build method - all bookings in provider: ${bookingProvider.bookings.map((b) => b.id).toList()}',
    );

    // Deep Blue: Loading state
    if (bookingProvider.isLoading && booking == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Deep Green: Error state
    if (booking == null) {
      // Check if we should retry automatically (for race conditions)
      final shouldRetry =
          bookingProvider.errorMessage == null &&
          !bookingProvider.isLoading &&
          _retryCount < 3;

      if (shouldRetry) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _retryCount++;
          print(
            'DEBUG: Auto-retry attempt $_retryCount for booking ${widget.bookingId}',
          );
          context.read<BookingProvider>().loadBooking(widget.bookingId);
        });
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: _BookingErrorState(
          message: bookingProvider.errorMessage ?? 'Booking not found.',
          onRetry: () {
            _retryCount = 0;
            context.read<BookingProvider>().loadBooking(widget.bookingId);
          },
        ),
      );
    }

    // Deep Blue: Find related data
    final request = _findRequest(requestProvider.requests, booking);
    if (request == null && booking.serviceRequestId.isNotEmpty) {
      requestProvider.fetchRequestById(booking.serviceRequestId);
    }
    final quote = quoteProvider.getQuoteById(booking.quoteId);
    final providerUser = booking.providerId == null
        ? null
        : providerDirectory.getProviderById(booking.providerId!);
    final customerUser = booking.customerId == null
        ? null
        : customerDirectory.getCustomerById(booking.customerId!);

    // Deep Green: Fetch missing profiles
    if (booking.providerId != null && providerUser == null) {
      _requestProviderProfile(providerDirectory, booking.providerId!);
    }
    if (booking.customerId != null && customerUser == null) {
      _requestCustomerProfile(customerDirectory, booking.customerId!);
    }

    if (quote == null && !_requestedQuotes) {
      _requestedQuotes = true;
      quoteProvider.loadMyQuotes();
    }

    final addressFallback = booking.address ?? request?.location ?? 'Not set';
    final priceLabel = quote == null
        ? 'Not set'
        : '\$${quote.price.toStringAsFixed(2)}';
    final providerDistance = formatDistanceKm(
      fromLat: request?.locationLat,
      fromLng: request?.locationLng,
      toLat: providerUser?.latitude,
      toLng: providerUser?.longitude,
    );

    // Deep Blue: Main scaffold with scrollable content
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusTimeline(status: booking.status),
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Booking Summary',
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Service',
                    value: request?.title ?? 'Service',
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: _statusLabel(booking.status),
                  ),
                  _DetailRow(
                    label: 'Category',
                    value: request?.category ?? 'Not set',
                  ),
                  if (booking.scheduledAt != null)
                    _DetailRow(
                      label: 'Scheduled',
                      value: _formatDateTime(booking.scheduledAt!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Address / Location',
              child: ResolvedAddressText(
                lat: request?.locationLat,
                lng: request?.locationLng,
                fallback: addressFallback,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if ((request?.photoPaths ?? []).isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailCard(
                title: 'Request Photos',
                child: _buildPhotoGallery(request!.photoPaths),
              ),
            ],
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Price Summary',
              child: _DetailRow(label: 'Total', value: priceLabel),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Provider',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openProviderProfile(
                  providerId: booking.providerId,
                  providerUser: providerUser,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: providerUser?.name ?? 'Unknown Provider',
                      imagePath: providerUser?.profilePicture,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            providerUser?.name ??
                                booking.providerId ??
                                'Unknown provider',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (providerDistance != 'N/A')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Distance: $providerDistance',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Customer',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoadingCustomerProfile && customerUser == null
                    ? null
                    : () => _openCustomerProfile(
                        customerId: booking.customerId,
                        customerUser: customerUser,
                      ),
                child: Row(
                  children: [
                    UserAvatar(
                      name: customerUser?.name ?? 'Unknown Customer',
                      imagePath: customerUser?.profilePicture,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCustomerProfileLabel(
                        customerUser,
                        booking.customerId,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (booking.status == BookingStatus.inProgress)
              _buildLiveLocationSection(providerUser),
            const SizedBox(height: 16),
            if (user?.role == UserRole.customer)
              _buildCustomerActions(
                context,
                booking,
                request,
                providerUser,
                quote,
              ),
            if (user?.role == UserRole.provider)
              _buildProviderActions(context, booking, request, customerUser),
            if (booking.status == BookingStatus.completed &&
                user?.role == UserRole.provider)
              _DetailCard(
                title: 'Job Completed',
                child: const Text(
                  'The job is marked as completed. Customer can now leave a review.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Deep Green: Request provider profile if not loaded
  void _requestProviderProfile(
    ProviderDirectoryProvider providerDirectory,
    String providerId,
  ) {
    if (_requestedProviderId == providerId) {
      return;
    }
    _requestedProviderId = providerId;
    // Fetch provider profile but handle 404 errors gracefully
    providerDirectory.fetchProviderById(providerId).catchError((e) {
      debugPrint('Provider profile not found: $providerId');
      return null;
    });
  }

  // Deep Blue: Request customer profile if not loaded
  void _requestCustomerProfile(
    CustomerDirectoryProvider customerDirectory,
    String customerId,
  ) {
    if (_requestedCustomerId == customerId) {
      return;
    }
    _requestedCustomerId = customerId;
    _setCustomerProfileLoading(true);
    customerDirectory
        .fetchCustomerById(customerId)
        .then((_) {
          if (!mounted) return;
          _setCustomerProfileLoading(false);
        })
        .catchError((e) {
          debugPrint('Customer profile not found: $customerId');
          if (!mounted) return;
          _setCustomerProfileLoading(false);
          return null;
        });
  }

  void _setCustomerProfileLoading(bool value) {
    if (_isLoadingCustomerProfile == value) {
      return;
    }
    setState(() {
      _isLoadingCustomerProfile = value;
    });
  }

  Widget _buildCustomerProfileLabel(
    UserModel? customerUser,
    String? customerId,
  ) {
    if (customerUser != null) {
      return Text(
        customerUser.name,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
    }

    if (_isLoadingCustomerProfile) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading customer profile...',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return Text(
      customerId ?? 'Unknown customer',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Future<void> _openProviderProfile({
    required String? providerId,
    required UserModel? providerUser,
  }) async {
    if (providerId == null || providerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider profile not available.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderProfileDetailScreen(
          providerId: providerId,
          initialProvider: providerUser,
        ),
      ),
    );
  }

  Future<void> _openCustomerProfile({
    required String? customerId,
    required UserModel? customerUser,
  }) async {
    if (customerUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerProfileDetailScreen(customer: customerUser),
        ),
      );
      return;
    }

    if (customerId == null || customerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer profile not available.')),
      );
      return;
    }

    final customerDirectory = context.read<CustomerDirectoryProvider>();
    final fetched = await customerDirectory.fetchCustomerById(customerId);
    if (!mounted) return;
    if (fetched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer profile not available.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerProfileDetailScreen(customer: fetched),
      ),
    );
  }

  // Deep Green: Build customer action buttons
  Widget _buildCustomerActions(
    BuildContext context,
    dynamic booking,
    ServiceRequest? request,
    UserModel? providerUser,
    Quote? quote,
  ) {
    final bookingProvider = context.read<BookingProvider>();
    final actions = <Widget>[];

    if (booking.status == BookingStatus.booked &&
        request != null &&
        quote != null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    request: request,
                    quote: quote,
                    bookingId: booking.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text('Pay Now'),
          ),
        ),
      );
    }

    if (booking.status == BookingStatus.booked) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final reason = await _askCancelReason(context);
              if (reason == null || reason.isEmpty) return;
              final result = await bookingProvider.cancel(
                bookingId: booking.id,
                reason: reason,
              );
              if (!context.mounted) return;
              if (result == null) {
                final message =
                    bookingProvider.errorMessage ?? 'Failed to cancel booking.';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Booking'),
          ),
        ),
      );
    }

    if (booking.status == BookingStatus.booked ||
        booking.status == BookingStatus.inProgress) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final serviceRequestId = request?.id ?? booking.serviceRequestId;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DisputeCreateScreen(
                    serviceRequestId: serviceRequestId,
                    serviceRequestTitle: request?.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.gavel),
            label: const Text('Raise Dispute'),
          ),
        ),
      );
    }

    if (providerUser?.id != null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageThreadScreen(
                    conversationId: null,
                    otherUserId: providerUser!.id,
                    otherUserName: providerUser.name,
                    otherUser: providerUser,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message Provider'),
          ),
        ),
      );
    }

    if (booking.status == BookingStatus.completed &&
        request != null &&
        providerUser?.id != null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(
                    providerId: providerUser!.id,
                    bookingId: booking.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.rate_review),
            label: const Text('Leave a Review'),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DetailCard(
      title: 'Customer Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: action,
              ),
            )
            .toList(),
      ),
    );
  }

  // Deep Blue: Build provider action buttons
  Widget _buildProviderActions(
    BuildContext context,
    dynamic booking,
    ServiceRequest? request,
    UserModel? customerUser,
  ) {
    final bookingProvider = context.read<BookingProvider>();
    final actions = <Widget>[];

    if (booking.status == BookingStatus.booked) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await _confirmStatusChange(
              context,
              title: 'Start job?',
              message: 'The booking will move to In Progress.',
            );
            if (!confirmed) return;
            final result = await bookingProvider.updateStatus(
              bookingId: booking.id,
              status: BookingStatus.inProgress,
            );
            if (!context.mounted) return;
            if (result == null) {
              final message =
                  bookingProvider.errorMessage ??
                  'Failed to update booking status.';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Job'),
        ),
      );
    }

    if (booking.status == BookingStatus.inProgress) {
      actions.add(
        ElevatedButton.icon(
          onPressed: () async {
            final confirmed = await _confirmStatusChange(
              context,
              title: 'Mark complete?',
              message: 'This will complete the job.',
            );
            if (!confirmed) return;
            final result = await bookingProvider.updateStatus(
              bookingId: booking.id,
              status: BookingStatus.completed,
            );
            if (!context.mounted) return;
            if (result == null) {
              final message =
                  bookingProvider.errorMessage ??
                  'Failed to update booking status.';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Job completed.')));
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark Completed'),
        ),
      );
    }

    if (customerUser?.id != null) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessageThreadScreen(
                  conversationId: null,
                  otherUserId: customerUser!.id,
                  otherUserName: customerUser.name,
                  otherUser: customerUser,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Message Customer'),
        ),
      );
      actions.add(
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CustomerProfileDetailScreen(customer: customerUser!),
              ),
            );
          },
          icon: const Icon(Icons.person_outline),
          label: const Text('View Customer Profile'),
        ),
      );
    }

    if (booking.status == BookingStatus.booked ||
        booking.status == BookingStatus.inProgress) {
      actions.add(
        OutlinedButton.icon(
          onPressed: () {
            final serviceRequestId = request?.id ?? booking.serviceRequestId;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DisputeCreateScreen(
                  serviceRequestId: serviceRequestId,
                  serviceRequestTitle: request?.title,
                ),
              ),
            );
          },
          icon: const Icon(Icons.gavel),
          label: const Text('Raise Dispute'),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DetailCard(
      title: 'Provider Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: action,
              ),
            )
            .toList(),
      ),
    );
  }

  // Deep Green: Build live location sharing section with map
  Widget _buildLiveLocationSection(UserModel? providerUser) {
    final hasLocation =
        providerUser?.latitude != null && providerUser?.longitude != null;

    return _DetailCard(
      title: 'Live Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share live location'),
            value: _isSharingLocation,
            onChanged: (value) => setState(() => _isSharingLocation = value),
          ),
          if (_isSharingLocation && hasLocation)
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    providerUser!.latitude!,
                    providerUser.longitude!,
                  ),
                  initialZoom: 14,
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
                          providerUser.latitude!,
                          providerUser.longitude!,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (_isSharingLocation)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Provider location is not available yet.'),
            ),
        ],
      ),
    );
  }

  // Deep Blue: Show confirmation dialog for status change
  Future<bool> _confirmStatusChange(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // Deep Green: Ask for cancellation reason
  Future<String?> _askCancelReason(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cancelling may incur fees based on your provider policy.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    return result?.trim();
  }

  // Deep Blue: Find request from list by ID
  ServiceRequest? _findRequest(List<ServiceRequest> requests, dynamic booking) {
    try {
      return requests.firstWhere((r) => r.id == booking.serviceRequestId);
    } catch (_) {
      return null;
    }
  }

  // Deep Green: Get human-readable status label
  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.booked:
        return 'Booked';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Deep Blue: Format DateTime for display
  String _formatDateTime(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
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
    if (_isServerRelative(path)) {
      return '${ApiConstants.baseUrl}$path';
    }
    return path;
  }

  bool _isRemotePath(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        _isServerRelative(path);
  }

  bool _isServerRelative(String path) {
    if (!path.startsWith('/')) return false;
    return path.startsWith('/uploads') ||
        path.startsWith('/media') ||
        path.startsWith('/files');
  }
}

// Deep Green: Error state widget for failed booking loads
class _BookingErrorState extends StatelessWidget {
  const _BookingErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact support: support@example.com'),
                  ),
                );
              },
              child: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }
}

// Deep Blue: Reusable detail card with shadow and padding
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Deep Green: Row with label and value pair
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Deep Blue: Timeline widget showing booking progress
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      BookingStatus.booked,
      BookingStatus.inProgress,
      BookingStatus.completed,
    ];

    return Row(
      children: steps
          .map(
            (step) => Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _isReached(step) ? Colors.green : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFor(step), color: Colors.white, size: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _labelFor(step),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isReached(step) ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // Deep Green: Check if this step has been reached
  bool _isReached(BookingStatus step) {
    final order = {
      BookingStatus.booked: 0,
      BookingStatus.inProgress: 1,
      BookingStatus.completed: 2,
      BookingStatus.cancelled: 3,
    };
    return order[status]! >= order[step]!;
  }

  // Deep Blue: Get label for each step
  String _labelFor(BookingStatus step) {
    switch (step) {
      case BookingStatus.booked:
        return 'Booked';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Deep Green: Get icon for each step
  IconData _iconFor(BookingStatus step) {
    switch (step) {
      case BookingStatus.booked:
        return Icons.event_available;
      case BookingStatus.inProgress:
        return Icons.play_arrow;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }
}
