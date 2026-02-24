import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/provider_directory_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/request_provider.dart';
import '../../shared/messages/messages_screen.dart';
import 'create_request_screen.dart';
import 'customer_profile_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomePage(
      onNavigateToTab: (index) => setState(() => _currentIndex = index),
    ),
    const RequestsPage(),
    const MessagesPage(),
    const CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12),
          ],
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
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Requests'),
              BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pages
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'n1',
      title: 'New quote received',
      message: 'John sent a quote for your request.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n2',
      title: 'Job started',
      message: 'Your job has started and is in progress.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Payment confirmed',
      message: 'Payment confirmed for Electrical Repair.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RequestProvider>().loadRequests());
    Future.microtask(
      () => context.read<ProviderDirectoryProvider>().loadProviders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final providerDirectory = context.watch<ProviderDirectoryProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();

    final currentUser = authProvider.currentUser;
    final customerName = currentUser?.name ?? 'Customer';
    final customerRequests = currentUser == null
        ? <ServiceRequest>[]
        : requestProvider.getCustomerRequests(currentUser.id);

    final activeRequests = customerRequests
        .where(
          (r) =>
              r.status == RequestStatus.pending ||
              r.status == RequestStatus.quoted,
        )
        .toList();
    final ongoingJobs = customerRequests
        .where((r) => r.status == RequestStatus.accepted)
        .toList();

    activeRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    ongoingJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentActiveRequests = activeRequests.take(3).toList();
    final allQuotes = customerRequests
      .expand((r) => quoteProvider.getQuotesForRequest(r.id))
      .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentQuotes = allQuotes.take(3).toList();

    final unreadMessagesCount = currentUser == null
      ? 0
      : messageProvider.getUnreadCountForUser(currentUser.id);
    final unreadNotificationsCount =
      _notifications.where((n) => !n.isRead).length;
    final newQuotesCount = allQuotes.length;
    final ongoingJobsCount = ongoingJobs.length;
    final activeRequestsCount = activeRequests.length;

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
                      const Icon(
                        Icons.waving_hand_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hello, $customerName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _NotificationBell(
                    count: unreadNotificationsCount,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationListScreen(
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
              const SizedBox(height: 6),
              const Text(
                "Here's your activity overview",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    icon: Icons.assignment_outlined,
                    label: 'Active Requests',
                    value: activeRequestsCount.toString(),
                  ),
                  _SummaryCard(
                    icon: Icons.mark_email_unread_outlined,
                    label: 'Unread Messages',
                    value: unreadMessagesCount.toString(),
                  ),
                  _SummaryCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'New Quotes',
                    value: newQuotesCount.toString(),
                  ),
                  _SummaryCard(
                    icon: Icons.star_border,
                    label: 'Ongoing Jobs',
                    value: ongoingJobsCount.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Active Requests',
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
                    children: recentActiveRequests.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No active requests yet'),
                            ),
                          ]
                        : recentActiveRequests
                            .map(
                              (req) {
                                final quoteCount = quoteProvider
                                    .getQuotesForRequest(req.id)
                                    .length;
                                final statusLabel =
                                    req.status == RequestStatus.pending
                                        ? 'Pending'
                                        : 'Quotes';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(req.category),
                                  subtitle: Text(req.location),
                                  trailing: Text(
                                    statusLabel == 'Pending'
                                        ? statusLabel
                                        : '\u2022 $quoteCount Quotes',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                );
                              },
                            )
                            .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Recent Quotes',
                actionLabel: 'View All Quotes',
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
                    children: recentQuotes.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No quotes yet'),
                            ),
                          ]
                        : List.generate(recentQuotes.length, (index) {
                            final quote = recentQuotes[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(quote.providerName),
                              subtitle: Text('\$${quote.price.toStringAsFixed(0)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(quote.rating.toStringAsFixed(1)),
                                ],
                              ),
                            );
                          }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'Current Job'),
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ongoingJobs.isEmpty
                      ? const Text('No ongoing jobs')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ongoingJobs.first.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text('Status: In Progress'),
                            const SizedBox(height: 6),
                            Text(
                              'Provider: ${recentQuotes.isEmpty ? 'Assigned' : recentQuotes.first.providerName}',
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'Notifications'),
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
                    children: _notifications.isEmpty
                        ? const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No notifications yet'),
                            ),
                          ]
                        : _notifications
                            .take(3)
                            .map(
                              (notification) => _NotificationTile(
                                icon: Icons.notifications_outlined,
                                text: notification.title,
                                isUnread: !notification.isRead,
                                onTap: () async {
                                  notification.isRead = true;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NotificationDetailScreen(
                                        notification: notification,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                              ),
                            )
                            .toList(),
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
  const _NotificationTile({
    required this.icon,
    required this.text,
    this.isUnread = false,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final bool isUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
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

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({required this.name, this.imagePath});

  final String name;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return CircleAvatar(
      radius: 20,
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

class ProviderDetailScreen extends StatelessWidget {
  const ProviderDetailScreen({
    super.key,
    required this.quote,
    required this.provider,
  });

  final Quote quote;
  final UserModel? provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProviderAvatar(
                  name: provider?.name ?? quote.providerName,
                  imagePath: provider?.profilePicture ?? quote.providerImage,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider?.name ?? quote.providerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(quote.rating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.phone,
              label: 'Phone',
              value: provider?.phone ?? quote.providerPhone ?? 'Not shared yet',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: provider?.location ??
                  quote.providerLocation ??
                  'Not shared yet',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.receipt_long,
              label: 'Quote',
              value: '\$${quote.price.toStringAsFixed(2)}',
            ),
            if ((provider?.bio ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.info_outline,
                label: 'Bio',
                value: provider!.bio!,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Message',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(quote.notes),
          ],
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

String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) {
    return 'P';
  }
  if (parts.length == 1) {
    return parts.first.characters.take(1).toString().toUpperCase();
  }
  return (parts[0].characters.take(1).toString() +
          parts[1].characters.take(1).toString())
      .toUpperCase();
}

class AppNotification {
  AppNotification({
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

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key, required this.notifications});

  final List<AppNotification> notifications;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
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
                        builder: (_) => NotificationDetailScreen(
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

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final AppNotification notification;

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

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => const MessagesScreen();
}

// ----------------- FULL FEATURE RequestsPage -----------------
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<RequestProvider>().loadRequests(),
    );
    Future.microtask(
      () => context.read<ProviderDirectoryProvider>().loadProviders(),
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
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();
    final providerDirectory = context.watch<ProviderDirectoryProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('No user logged in'));
    }

    final requests = requestProvider.getCustomerRequests(currentUser.id);

    return Scaffold(
      body: requestProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(child: Text('No requests yet'))
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final List<Quote> quotes =
                        quoteProvider.getQuotesForRequest(req.id);
                    final bool canAccept =
                        req.status == RequestStatus.pending;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${req.category} - ${req.location}'),
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
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(req.description),
                        ),
                        children: [
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'Quotes:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...quotes.map(
                            (q) {
                              final provider = q.providerId == null
                                  ? null
                                  : providerDirectory.getProviderById(
                                      q.providerId!,
                                    );
                              final providerName =
                                  provider?.name ?? q.providerName;
                              final providerLocation =
                                  provider?.location ?? q.providerLocation;
                              final providerImage =
                                  provider?.profilePicture ?? q.providerImage;

                              return ListTile(
                                leading: _ProviderAvatar(
                                  name: providerName,
                                  imagePath: providerImage,
                                ),
                                title: Text(
                                  '$providerName - \$${q.price.toStringAsFixed(2)}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q.notes),
                                    const SizedBox(height: 2),
                                    Text(
                                      providerLocation ?? 'Location not set',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: canAccept
                                    ? ElevatedButton(
                                        child: const Text('Accept'),
                                        onPressed: () {
                                          Provider.of<RequestProvider>(
                                            context,
                                            listen: false,
                                          ).updateStatus(
                                            req.id,
                                            RequestStatus.accepted,
                                          );

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Request accepted!'),
                                            ),
                                          );
                                        },
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProviderDetailScreen(
                                        quote: q,
                                        provider: provider,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateRequestScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Request'),
      ),
    );
  }
}