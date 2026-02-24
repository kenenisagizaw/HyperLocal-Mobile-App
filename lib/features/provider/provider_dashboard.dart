import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_directory_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/request_provider.dart';
import '../profile/profile_screen.dart';
import '../../shared/messages/messages_screen.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentIndex = 0;

  List<Widget> _buildPages() {
    return [
      ProviderHomePage(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      const AvailableJobsPage(),
      const MyQuotesPage(),
      const MessagesPage(),
      const ProviderProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.blueGrey,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 22),
            elevation: 10,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money),
                label: 'Quotes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- Provider Home -------------------

class ProviderHomePage extends StatefulWidget {
  const ProviderHomePage({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  final List<_AppNotification> _notifications = [
    _AppNotification(
      id: 'p1',
      title: 'New request received',
      message: 'A new request is available in your area.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    _AppNotification(
      id: 'p2',
      title: 'Quote accepted',
      message: 'John accepted your quote.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _AppNotification(
      id: 'p3',
      title: 'New review',
      message: 'You received a new review.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RequestProvider>().loadRequests());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();

    final currentUser = authProvider.currentUser;
    final providerName = currentUser?.name ?? 'Provider';
    final providerQuotes = currentUser?.id == null
      ? <Quote>[]
      : quoteProvider.quotes
        .where((q) => q.providerId == currentUser!.id)
        .toList();
    final rating = providerQuotes.isEmpty
        ? 4.7
      : providerQuotes
          .map((q) => q.rating)
          .fold<double>(0, (sum, value) => sum + value) /
        providerQuotes.length;
    final unreadNotificationsCount =
        _notifications.where((n) => !n.isRead).length;

    final activeJobs = requestProvider.requests
        .where((r) => r.status == RequestStatus.accepted)
        .toList();
    final newOpportunities = requestProvider.requests
        .where(
          (r) =>
              r.status == RequestStatus.pending ||
              r.status == RequestStatus.quoted,
        )
        .toList();

    final todayQuotes = providerQuotes
        .where(
          (q) =>
              q.createdAt.year == DateTime.now().year &&
              q.createdAt.month == DateTime.now().month &&
              q.createdAt.day == DateTime.now().day,
        )
        .toList();
    final earningsToday = todayQuotes.fold<double>(
      0,
      (sum, quote) => sum + quote.price,
    );

    final activeJobsPreview = activeJobs.take(2).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          _getInitials(providerName),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $providerName',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Here's your business overview",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _NotificationBell(
                    count: unreadNotificationsCount,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _NotificationListScreen(
                            notifications: _notifications,
                          ),
                        ),
                      );
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Text('Online'),
                      Switch(
                        value: _isOnline,
                        onChanged: (value) => setState(() => _isOnline = value),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    icon: Icons.work_outline,
                    label: 'Active Jobs',
                    value: activeJobs.length.toString(),
                  ),
                  _SummaryCard(
                    icon: Icons.notifications_active_outlined,
                    label: 'New Requests',
                    value: newOpportunities.length.toString(),
                  ),
                  _SummaryCard(
                    icon: Icons.star_border,
                    label: 'Rating',
                    value: '${rating.toStringAsFixed(1)}⭐',
                  ),
                  _SummaryCard(
                    icon: Icons.attach_money,
                    label: 'Earnings Today',
                    value: '\$${earningsToday.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Active Jobs',
                actionLabel: 'View All',
                onActionTap: () => widget.onNavigateToTab(1),
              ),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: activeJobsPreview.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No active jobs yet'),
                            ),
                          ]
                        : activeJobsPreview
                            .map(
                              (job) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(job.category),
                                subtitle: Text('Customer: ${job.customerId}'),
                                trailing: const Text(
                                  'In Progress',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'Recent Activity'),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: const [
                      _NotificationTile(
                        icon: Icons.notifications_outlined,
                        text: 'You received a new request',
                      ),
                      _NotificationTile(
                        icon: Icons.check_circle_outline,
                        text: 'John accepted your quote',
                      ),
                      _NotificationTile(
                        icon: Icons.star_border,
                        text: 'New review added',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'This Week'),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jobs Completed: ${activeJobs.length + 2}'),
                      const SizedBox(height: 6),
                      Text(
                        'Total Earnings: \$${(earningsToday + 200).toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 6),
                      Text('Average Rating: ${rating.toStringAsFixed(1)}⭐'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue),
      title: Text(text),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none, color: Colors.black87),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AppNotification {
  _AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
}

class _NotificationListScreen extends StatefulWidget {
  const _NotificationListScreen({required this.notifications});

  final List<_AppNotification> notifications;

  @override
  State<_NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends State<_NotificationListScreen> {
  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: notification.isRead
                        ? Colors.blueGrey
                        : Colors.blue,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: Text(
                    _formatNotificationTime(notification.createdAt),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  onTap: () async {
                    setState(() => notification.isRead = true);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _NotificationDetailScreen(
                          notification: notification,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationDetailScreen extends StatelessWidget {
  const _NotificationDetailScreen({required this.notification});

  final _AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatNotificationTime(notification.createdAt),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Text(notification.message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

String _formatNotificationTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}

String _formatRequestStatus(RequestStatus status) {
  return status
      .toString()
      .split('.')
      .last
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
      .trim();
}

String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'P';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

// ------------------- Available Jobs -------------------

class AvailableJobsPage extends StatefulWidget {
  const AvailableJobsPage({super.key});

  @override
  State<AvailableJobsPage> createState() => _AvailableJobsPageState();
}

class _AvailableJobsPageState extends State<AvailableJobsPage> {
  String _selectedCategory = 'All';
  double _maxDistanceKm = 25;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RequestProvider>().loadRequests());
    Future.microtask(
      () => context.read<CustomerDirectoryProvider>().loadCustomers(),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.quoted:
        return Colors.purple;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    final requests = Provider.of<RequestProvider>(context).requests;
    final quoteProvider = Provider.of<QuoteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final customerDirectory = Provider.of<CustomerDirectoryProvider>(context);
    final providerUser = authProvider.currentUser;

    final categories = <String>{'All'};
    for (final request in requests) {
      categories.add(request.category);
    }

    final filteredRequests = requests.where((request) {
      final matchesCategory =
          _selectedCategory == 'All' || request.category == _selectedCategory;
      if (!matchesCategory) {
        return false;
      }

      final distanceKm = _calculateDistanceKm(
        providerUser,
        request.locationLat,
        request.locationLng,
      );

      if (distanceKm == null) {
        return true;
      }

      return distanceKm <= _maxDistanceKm;
    }).toList();

    if (requests.isEmpty) {
      return const Center(child: Text('No available jobs'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedCategory = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance: ${_maxDistanceKm.toStringAsFixed(0)} km'),
                    Slider(
                      value: _maxDistanceKm,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                      onChanged: (value) =>
                          setState(() => _maxDistanceKm = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredRequests.isEmpty
              ? const Center(child: Text('No jobs match your filters'))
              : ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final req = filteredRequests[index];
        final customer = customerDirectory.getCustomerById(req.customerId);
        final isDisabled =
            req.status == RequestStatus.accepted ||
            req.status == RequestStatus.completed ||
            req.status == RequestStatus.cancelled;

        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: _UserAvatar(
              name: customer?.name ?? 'Customer',
              imagePath: customer?.profilePicture,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${req.category} • ${req.location}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(req.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(req.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(req.description),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${customer?.name ?? req.customerId}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabled ? Colors.grey : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // ignore: sort_child_properties_last
              child: const Text('Quote'),
              onPressed: isDisabled
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(
                            request: req,
                            customer: customer,
                            providerUser: providerUser,
                          ),
                        ),
                      );
                    },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(
                    request: req,
                    customer: customer,
                    providerUser: providerUser,
                  ),
                ),
              );
            },
          ),
        );
                  },
                ),
        ),
      ],
    );
  }
}

double? _calculateDistanceKm(
  UserModel? from,
  double? toLat,
  double? toLng,
) {
  if (from?.latitude == null ||
      from?.longitude == null ||
      toLat == null ||
      toLng == null) {
    return null;
  }

  const earthRadiusKm = 6371.0;
  final lat1 = _toRadians(from!.latitude!);
  final lon1 = _toRadians(from.longitude!);
  final lat2 = _toRadians(toLat);
  final lon2 = _toRadians(toLng);
  final dLat = lat2 - lat1;
  final dLon = lon2 - lon1;

  final a = pow(sin(dLat / 2), 2) +
      cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degree) => degree * (pi / 180.0);

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

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitQuote() {
    final quoteProvider = context.read<QuoteProvider>();
    final priceText = _priceController.text.trim();
    final notes = _notesController.text.trim();

    if (priceText.isEmpty || notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter price and notes to send a quote.')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price.')),
      );
      return;
    }

    final providerUser = widget.providerUser;

    quoteProvider.addQuote(
      Quote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        requestId: widget.request.id,
        providerName: providerUser?.name ?? 'Provider',
        price: price,
        notes: notes,
        providerId: providerUser?.id,
        providerPhone: providerUser?.phone,
        providerLocation: providerUser?.location,
        providerImage: providerUser?.profilePicture,
        rating: 4.9,
        createdAt: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote submitted')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final customer = widget.customer;
    final hasLocation = request.locationLat != null && request.locationLng != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.category,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.place,
              label: 'Location',
              value: request.location,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.attach_money,
              label: 'Budget',
              value: '\$${request.budget.toStringAsFixed(0)}',
            ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        LatLng(request.locationLat!, request.locationLng!),
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
                          point:
                              LatLng(request.locationLat!, request.locationLng!),
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
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Customer Profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _CustomerProfileCard(customer: customer),
            const SizedBox(height: 20),
            const Text(
              'Send Quote',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitQuote,
                child: const Text('Send Quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerProfileCard extends StatelessWidget {
  const _CustomerProfileCard({required this.customer});

  final UserModel? customer;

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
      return const Text('Customer profile not available.');
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _UserAvatar(name: customer!.name, imagePath: customer!.profilePicture),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer!.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(customer!.phone),
                  const SizedBox(height: 4),
                  Text(customer!.address ?? 'Address not set'),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CustomerProfileDetailScreen(
                      customer: customer!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerProfileDetailScreen extends StatelessWidget {
  const _CustomerProfileDetailScreen({required this.customer});

  final UserModel customer;

  @override
  Widget build(BuildContext context) {
    final hasLocation = customer.latitude != null && customer.longitude != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UserAvatar(
                  name: customer.name,
                  imagePath: customer.profilePicture,
                  radius: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.phone,
              label: 'Phone',
              value: customer.phone,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.email,
              label: 'Email',
              value: customer.email ?? 'Not shared yet',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Address',
              value: customer.address ?? 'Not shared yet',
            ),
            if (hasLocation) ...[
              const SizedBox(height: 16),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        LatLng(customer.latitude!, customer.longitude!),
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
                          point: LatLng(customer.latitude!, customer.longitude!),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    this.imagePath,
    this.radius = 20,
  });

  final String name;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final initials = _getInitials(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      backgroundImage: hasImage ? FileImage(File(imagePath!)) : null,
      child: hasImage
          ? null
          : Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(value)),
      ],
    );
  }
}

// ------------------- My Quotes -------------------

class MyQuotesPage extends StatefulWidget {
  const MyQuotesPage({super.key});

  @override
  State<MyQuotesPage> createState() => _MyQuotesPageState();
}

class _MyQuotesPageState extends State<MyQuotesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RequestProvider>().loadRequests());
    Future.microtask(
      () => context.read<CustomerDirectoryProvider>().loadCustomers(),
    );
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
            .toList();

    if (quotes.isEmpty) {
      return const Center(child: Text('No quotes yet'));
    }

    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final q = quotes[index];
        final request = requestProvider.requests
            .where((r) => r.id == q.requestId)
            .cast<ServiceRequest?>()
            .firstWhere(
              (r) => r != null,
              orElse: () => null,
            );
        final customer = request == null
            ? null
            : customerDirectory.getCustomerById(request.customerId);

        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: _UserAvatar(
              name: customer?.name ?? 'Customer',
              imagePath: customer?.profilePicture,
            ),
            title: Text(
              '\$${q.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.notes),
                const SizedBox(height: 4),
                Text(
                  request == null
                      ? 'Request info unavailable'
                      : '${request.category} • ${request.location}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'Customer: ${customer?.name ?? request?.customerId ?? 'Unknown'}',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (request != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Status: ${_formatRequestStatus(request.status)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ],
            ),
            trailing: Text(
              _formatNotificationTime(q.createdAt),
              style: const TextStyle(color: Colors.black54),
            ),
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
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        request?.locationLat != null && request?.locationLng != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Quote Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${quote.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(quote.notes),
            const SizedBox(height: 16),
            if (request != null) ...[
              _DetailRow(
                icon: Icons.work_outline,
                label: 'Request',
                value: request!.category,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.info_outline,
                label: 'Status',
                value: _formatRequestStatus(request!.status),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.place,
                label: 'Location',
                value: request!.location,
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Details',
                value: request!.description,
              ),
            ],
            if (hasLocation) ...[
              const SizedBox(height: 12),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        LatLng(request!.locationLat!, request!.locationLng!),
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
                          point:
                              LatLng(request!.locationLat!, request!.locationLng!),
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
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Customer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _CustomerProfileCard(customer: customer),
          ],
        ),
      ),
    );
  }
}

// ------------------- Messages -------------------

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) => const MessagesScreen();
}
