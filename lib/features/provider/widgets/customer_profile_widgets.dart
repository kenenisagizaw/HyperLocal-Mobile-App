import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/distance_utils.dart';
import '../../../core/widgets/resolved_address_text.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_directory_provider.dart';
import '../../customer/providers/provider_directory_provider.dart';
import '../../messages/messages_screen.dart';
import '../../reviews/provider_reviews_screen.dart';
import '../../reviews/providers/review_provider.dart';
import 'user_avatar.dart';

class CustomerProfileCard extends StatefulWidget {
  const CustomerProfileCard({super.key, this.customer, this.customerId});

  final UserModel? customer;
  final String? customerId;

  @override
  State<CustomerProfileCard> createState() => _CustomerProfileCardState();
}

class _CustomerProfileCardState extends State<CustomerProfileCard> {
  UserModel? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _isLoading = widget.customer == null && widget.customerId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.customer != null || widget.customerId == null) {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final directory = context.read<CustomerDirectoryProvider>();
      final cached = directory.getCustomerById(widget.customerId!);
      if (cached != null) {
        setState(() {
          _customer = cached;
          _isLoading = false;
        });
        return;
      }
      final fetched = await directory.fetchCustomerById(widget.customerId!);
      if (!mounted) return;
      setState(() {
        _customer = fetched;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _customer == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_customer == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('Customer profile not available.'),
      );
    }

    final customer = _customer!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerProfileDetailScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(
                name: customer.name,
                imagePath: customer.profilePicture,
                radius: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.address ?? 'Address not set',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
  }
}

class CustomerProfileDetailScreen extends StatelessWidget {
  const CustomerProfileDetailScreen({super.key, required this.customer});

  final UserModel customer;

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final hasLocation = customer.latitude != null && customer.longitude != null;
    final currentUser = context.read<AuthProvider>().currentUser;
    final canMessage = currentUser != null && currentUser.id != customer.id;
    final distanceLabel = formatDistanceKm(
      fromLat: currentUser?.latitude,
      fromLng: currentUser?.longitude,
      toLat: customer.latitude,
      toLng: customer.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
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
                  colors: [_primaryBlue.withValues(alpha: 0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: customer.name,
                    imagePath: customer.profilePicture,
                    radius: 40,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer since ${_formatJoinDate(customer.createdAt)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (canMessage) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(
                          conversationId: null,
                          otherUserId: customer.id,
                          otherUserName: customer.name,
                          otherUser: customer,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _InfoSection(
              title: 'Contact Information',
              children: [
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  value: customer.phone,
                ),
                _InfoRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: customer.email ?? 'Not shared',
                ),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  value: customer.address ?? 'Not shared',
                  valueWidget: ResolvedAddressText(
                    lat: customer.latitude,
                    lng: customer.longitude,
                    fallback: customer.address ?? 'Not shared',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (distanceLabel != 'N/A')
                  _InfoRow(
                    icon: Icons.route_rounded,
                    label: 'Distance',
                    value: distanceLabel,
                  ),
              ],
            ),
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
                      customer.latitude!,
                      customer.longitude!,
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
                            customer.latitude!,
                            customer.longitude!,
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
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Recently';
    return '${date.month}/${date.year}';
  }
}

class ProviderProfileDetailScreen extends StatefulWidget {
  const ProviderProfileDetailScreen({
    super.key,
    required this.providerId,
    this.initialProvider,
  });

  final String providerId;
  final UserModel? initialProvider;

  @override
  State<ProviderProfileDetailScreen> createState() =>
      _ProviderProfileDetailScreenState();
}

class _ProviderProfileDetailScreenState
    extends State<ProviderProfileDetailScreen> {
  UserModel? _provider;
  bool _isLoading = true;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<ReviewProvider>().loadProviderReviews(
        providerId: widget.providerId,
        take: 10,
      );
      final directory = context.read<ProviderDirectoryProvider>();
      final cached = directory.getProviderById(widget.providerId);
      if (cached != null) {
        setState(() {
          _provider = cached;
          _isLoading = false;
        });
        return;
      }
      final fetched = await directory.fetchProviderById(widget.providerId);
      if (!mounted) return;
      setState(() {
        _provider = fetched;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _provider == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_provider == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Profile'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Text(
            'Provider profile not available.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final provider = _provider!;
    final hasLocation = provider.latitude != null && provider.longitude != null;
    final hasProviderProfile = _hasProviderProfile(provider);
    final reviewProvider = context.watch<ReviewProvider>();
    final reviews = reviewProvider.getReviewsForProvider(provider.id);
    final averageRating = reviewProvider.averageRating;
    final currentUser = context.read<AuthProvider>().currentUser;
    final canMessage = currentUser != null && currentUser.id != provider.id;
    final distanceLabel = formatDistanceKm(
      fromLat: currentUser?.latitude,
      fromLng: currentUser?.longitude,
      toLat: provider.latitude,
      toLng: provider.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
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
                    _primaryGreen.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: provider.name,
                    imagePath: provider.profilePicture,
                    radius: 42,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (provider.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.bio ?? 'No bio provided',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (canMessage) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(
                          conversationId: null,
                          otherUserId: provider.id,
                          otherUserName: provider.name,
                          otherUser: provider,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _InfoSection(
              title: 'Contact Information',
              children: [
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  value: provider.phone,
                ),
                _InfoRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: provider.email ?? 'Not shared',
                ),
                _InfoRow(
                  icon: Icons.location_city_rounded,
                  label: 'City',
                  value: provider.city ?? 'Not shared',
                ),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  value: provider.address ?? provider.location ?? 'Not shared',
                ),
                if (distanceLabel != 'N/A')
                  _InfoRow(
                    icon: Icons.route_rounded,
                    label: 'Distance',
                    value: distanceLabel,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (!hasProviderProfile)
              _InfoSection(
                title: 'Provider Details',
                children: [
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Status',
                    value: 'Provider profile not completed yet',
                  ),
                ],
              )
            else ...[
              _InfoSection(
                title: 'Provider Details',
                children: [
                  _InfoRow(
                    icon: Icons.business_center_rounded,
                    label: 'Business',
                    value: provider.businessName ?? 'Not shared',
                  ),
                  _InfoRow(
                    icon: Icons.category_rounded,
                    label: 'Service',
                    value: provider.serviceCategory ?? 'Not shared',
                  ),
                  _InfoRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Hourly Rate',
                    value: provider.hourlyRate == null
                        ? 'Not set'
                        : '\$${provider.hourlyRate!.toStringAsFixed(0)}',
                  ),
                  _InfoRow(
                    icon: Icons.place_rounded,
                    label: 'Service Radius',
                    value: provider.serviceRadius == null
                        ? 'Not set'
                        : '${provider.serviceRadius!.toStringAsFixed(0)} km',
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Availability',
                    value: provider.availabilityStatus ?? 'Not shared',
                  ),
                  _InfoRow(
                    icon: Icons.star_rounded,
                    label: 'Rating',
                    value: reviews.isEmpty
                        ? 'Not rated'
                        : averageRating.toStringAsFixed(1),
                  ),
                  _InfoRow(
                    icon: Icons.rate_review_rounded,
                    label: 'Reviews',
                    value: reviews.isEmpty ? '0' : reviews.length.toString(),
                  ),
                  _InfoRow(
                    icon: Icons.task_alt_rounded,
                    label: 'Completed Jobs',
                    value: provider.completedJobs?.toString() ?? '0',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _InfoSection(
              title: 'Recent Reviews',
              children: reviews.isEmpty
                  ? [const Text('No reviews yet.')]
                  : reviews
                        .take(5)
                        .map(
                          (review) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${review.rating}/5 - ${review.comment}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: reviews.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderReviewsScreen(
                              providerId: provider.id,
                              providerName: provider.name,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('See all reviews'),
              ),
            ),
            if (hasProviderProfile && hasLocation) ...[
              const SizedBox(height: 20),
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
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
                      provider.latitude!,
                      provider.longitude!,
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
                            provider.latitude!,
                            provider.longitude!,
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
          ],
        ),
      ),
    );
  }

  bool _hasProviderProfile(UserModel provider) {
    return (provider.businessName?.isNotEmpty ?? false) ||
        (provider.serviceCategory?.isNotEmpty ?? false) ||
        provider.hourlyRate != null ||
        provider.serviceRadius != null ||
        (provider.availabilityStatus?.isNotEmpty ?? false) ||
        provider.portfolioUrls.isNotEmpty ||
        provider.certificationsUrls.isNotEmpty;
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (valueWidget != null)
                  valueWidget!
                else
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
