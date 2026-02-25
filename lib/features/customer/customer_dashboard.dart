import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/service_request_model.dart';
import '../auth/providers/auth_provider.dart';
import '../messages/messages_screen.dart';
import '../messages/providers/message_provider.dart';
import '../payments/providers/payment_provider.dart';
import 'providers/provider_directory_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/request_provider.dart';
import 'request_detail_screen.dart';
import 'create_request_screen.dart';
import 'customer_profile_screen.dart';

/// ----------------- CUSTOMER DASHBOARD -----------------
class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomePage(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
    const RequestsPage(),
    const MessagesPage(),
    const PaymentsPage(),
    const CustomerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey.shade500,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
              BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Messages'),
              BottomNavigationBarItem(icon: Icon(Icons.payment_outlined), label: 'Payments'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- HOME PAGE -----------------
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RequestProvider>().loadRequests();
      context.read<ProviderDirectoryProvider>().loadProviders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();

    final currentUser = authProvider.currentUser;
    final customerName = currentUser?.name ?? 'Customer';
    final customerRequests = currentUser == null
        ? <ServiceRequest>[]
        : requestProvider.getCustomerRequests(currentUser.id);

    final activeRequests = customerRequests
        .where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.quoted)
        .toList();
    final ongoingJobs = customerRequests.where((r) => r.status == RequestStatus.accepted).toList();

    activeRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    ongoingJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentActiveRequests = activeRequests.take(3).toList();
    final allQuotes = customerRequests.expand((r) => quoteProvider.getQuotesForRequest(r.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentQuotes = allQuotes.take(3).toList();

    final unreadMessagesCount = currentUser == null ? 0 : messageProvider.getUnreadCountForUser(currentUser.id);
    final unreadNotificationsCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Greeting + Notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.waving_hand_outlined, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text('Hello, $customerName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _NotificationBell(
                    count: unreadNotificationsCount,
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => NotificationListScreen(
                            notifications: _notifications,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text("Here's your activity overview", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),

              /// Summary Cards
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(icon: Icons.assignment_outlined, label: 'Active Requests', value: activeRequests.length.toString()),
                  _SummaryCard(icon: Icons.mark_email_unread_outlined, label: 'Unread Messages', value: unreadMessagesCount.toString()),
                  _SummaryCard(icon: Icons.receipt_long_outlined, label: 'New Quotes', value: allQuotes.length.toString()),
                  _SummaryCard(icon: Icons.star_border, label: 'Ongoing Jobs', value: ongoingJobs.length.toString()),
                ],
              ),
              const SizedBox(height: 24),

              /// Active Requests Section
              _SectionHeader(title: 'Active Requests', actionLabel: 'View All', onActionTap: () => widget.onNavigateToTab(1)),
              ...recentActiveRequests.isEmpty
                  ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No active requests yet'))]
                  : recentActiveRequests.map((req) {
                      final quoteCount = quoteProvider.getQuotesForRequest(req.id).length;
                      final statusLabel = req.status == RequestStatus.pending ? 'Pending' : '\u2022 $quoteCount Quotes';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(req.category),
                        subtitle: Text(req.location),
                        trailing: Text(statusLabel, style: const TextStyle(color: Colors.black54)),
                      );
                    }).toList(),

              const SizedBox(height: 24),

              /// Recent Quotes Section
              _SectionHeader(title: 'Recent Quotes', actionLabel: 'View All Quotes', onActionTap: () => widget.onNavigateToTab(1)),
              ...recentQuotes.isEmpty
                  ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No quotes yet'))]
                  : recentQuotes.map((quote) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(quote.providerName),
                        subtitle: Text('\$${quote.price.toStringAsFixed(0)}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(quote.rating.toStringAsFixed(1)),
                        ]),
                      )).toList(),

              const SizedBox(height: 24),

              /// Ongoing Jobs Section
              const _SectionHeader(title: 'Current Job'),
              ongoingJobs.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No ongoing jobs'))
                  : ListTile(
                      title: Text(ongoingJobs.first.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Provider: ${recentQuotes.isEmpty ? 'Assigned' : recentQuotes.first.providerName}'),
                      trailing: const Text('In Progress'),
                    ),

              const SizedBox(height: 24),

              /// Notifications Section
              const _SectionHeader(title: 'Notifications'),
              ..._notifications.take(3).map((n) => _NotificationTile(
                    icon: Icons.notifications_outlined,
                    text: n.title,
                    isUnread: !n.isRead,
                          onTap: () async {
                            n.isRead = true;
                            final navigator = Navigator.of(context);
                            await navigator.push(
                              MaterialPageRoute(
                                builder: (_) => NotificationDetailScreen(
                                  notification: n,
                                ),
                              ),
                            );
                            if (!mounted) return;
                            setState(() {});
                          },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------- REUSABLE WIDGETS -----------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value});
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onActionTap});
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (actionLabel != null && onActionTap != null) TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.icon, required this.text, this.isUnread = false, this.onTap});
  final IconData icon;
  final String text;
  final bool isUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(text, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
      trailing: isUnread
          ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))
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
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(onPressed: onTap, icon: const Icon(Icons.notifications_none, color: Colors.black87)),
      if (count > 0)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints(minWidth: 18),
            child: Text(count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
    ]);
  }
}

/// ----------------- MESSAGES -----------------
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => const MessagesScreen();
}

/// ----------------- PAYMENTS -----------------
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser == null) return const Center(child: Text('No user logged in'));

    final payments = paymentProvider.payments.where((p) => p.payerId == currentUser.id).toList();
    if (payments.isEmpty) return const Center(child: Text('No payments yet'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        ServiceRequest? request;
        Quote? quote;
        try { request = requestProvider.requests.firstWhere((r) => r.id == payment.requestId); } catch (_) { request = null; }
        try { quote = quoteProvider.quotes.firstWhere((q) => q.id == payment.quoteId); } catch (_) { quote = null; }

        return Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            title: Text('\$${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request?.category ?? 'Service request'),
              const SizedBox(height: 4),
              Text('Provider: ${quote?.providerName ?? 'Unknown'}', style: const TextStyle(color: Colors.black54)),
            ]),
            trailing: Text(payment.createdAt.toLocal().toString().split(' ').first, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ),
        );
      },
    );
  }
}

/// ----------------- REQUESTS -----------------
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RequestProvider>().loadRequests();
      context.read<ProviderDirectoryProvider>().loadProviders();
    });
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
    return status.toString().split('.').last.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser == null) return const Center(child: Text('No user logged in'));

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
                    final List<Quote> quotes = quoteProvider.getQuotesForRequest(req.id);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('${req.category} - ${req.location}'),
                        subtitle: Text(req.description),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _getStatusColor(req.status), borderRadius: BorderRadius.circular(8)),
                          child: Text(_getStatusText(req.status), style: const TextStyle(color: Colors.white)),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(request: req, quotes: quotes))),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Create Request'),
      ),
    );
  }
}

/// ----------------- NOTIFICATIONS -----------------
class AppNotification {
  AppNotification({required this.id, required this.title, required this.message, required this.createdAt, this.isRead = false});
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
}

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({required this.notifications, super.key});
  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return ListTile(
            title: Text(n.title),
            subtitle: Text(n.message),
            trailing: n.isRead ? null : const Icon(Icons.circle, color: Colors.red, size: 10),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationDetailScreen(notification: n))),
          );
        },
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({required this.notification, super.key});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(notification.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(notification.message, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
