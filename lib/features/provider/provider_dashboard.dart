import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/quote_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/request_provider.dart';
import '../profile/profile_screen.dart';

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

class AvailableJobsPage extends StatelessWidget {
  const AvailableJobsPage({super.key});

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
    final providerUser = authProvider.currentUser;

    if (requests.isEmpty) {
      return const Center(child: Text('No available jobs'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
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
              child: Text(req.description),
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
                      quoteProvider.addQuote(
                        Quote(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          requestId: req.id,
                          providerName: providerUser?.name ?? 'Provider',
                          price: 1500,
                          notes: 'I can do it',
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
                    },
            ),
          ),
        );
      },
    );
  }
}

// ------------------- My Quotes -------------------

class MyQuotesPage extends StatelessWidget {
  const MyQuotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quotes = Provider.of<QuoteProvider>(context).quotes;

    if (quotes.isEmpty) {
      return const Center(child: Text('No quotes yet'));
    }

    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final q = quotes[index];

        return Card(
          margin: const EdgeInsets.all(12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              '\$${q.price}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            subtitle: Text(q.notes),
          ),
        );
      },
    );
  }
}

// ------------------- Messages -------------------

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Messages', style: TextStyle(fontSize: 18)),
    );
  }
}
