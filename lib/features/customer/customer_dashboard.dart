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
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A3366FF), // Blue tint shadow
              blurRadius: 12,
              offset: Offset(0, -4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF3366FF), // Primary blue
            unselectedItemColor: Colors.grey.shade400,
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
      backgroundColor: const Color(0xFFF8FAFF), // Light blue background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Greeting + Notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3366FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.waving_hand_outlined, 
                          color: Color(0xFF3366FF), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello,', 
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                          Text(customerName, 
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            )),
                        ],
                      ),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366FF).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF3366FF), size: 20),
                    const SizedBox(width: 8),
                    const Text("Here's your activity overview", 
                      style: TextStyle(color: Color(0xFF4A4E69), fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// Summary Cards
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    icon: Icons.assignment_outlined, 
                    label: 'Active Requests', 
                    value: activeRequests.length.toString(),
                    color: const Color(0xFF3366FF),
                  ),
                  _SummaryCard(
                    icon: Icons.mark_email_unread_outlined, 
                    label: 'Unread Messages', 
                    value: unreadMessagesCount.toString(),
                    color: const Color(0xFF00C48C), // Green accent
                  ),
                  _SummaryCard(
                    icon: Icons.receipt_long_outlined, 
                    label: 'New Quotes', 
                    value: allQuotes.length.toString(),
                    color: const Color(0xFF3366FF),
                  ),
                  _SummaryCard(
                    icon: Icons.star_border, 
                    label: 'Ongoing Jobs', 
                    value: ongoingJobs.length.toString(),
                    color: const Color(0xFF00C48C), // Green accent
                  ),
                ],
              ),
              const SizedBox(height: 28),

              /// Active Requests Section
              _SectionHeader(
                title: 'Active Requests', 
                actionLabel: 'View All', 
                onActionTap: () => widget.onNavigateToTab(1),
              ),
              const SizedBox(height: 8),
              ...recentActiveRequests.isEmpty
                  ? [Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No active requests yet',
                            style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )]
                  : recentActiveRequests.map((req) {
                      final quoteCount = quoteProvider.getQuotesForRequest(req.id).length;
                      final statusLabel = req.status == RequestStatus.pending 
                          ? 'Pending' 
                          : '\u2022 $quoteCount Quotes';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3366FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.build_circle_outlined, 
                              color: const Color(0xFF3366FF), size: 20),
                          ),
                          title: Text(req.category, 
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(req.location, 
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: req.status == RequestStatus.pending 
                                  ? const Color(0xFFFFB800).withOpacity(0.1)
                                  : const Color(0xFF00C48C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(statusLabel, 
                              style: TextStyle(
                                color: req.status == RequestStatus.pending 
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFF00C48C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                          ),
                        ),
                      );
                    }).toList(),

              const SizedBox(height: 24),

              /// Recent Quotes Section
              _SectionHeader(
                title: 'Recent Quotes', 
                actionLabel: 'View All Quotes', 
                onActionTap: () => widget.onNavigateToTab(1),
              ),
              const SizedBox(height: 8),
              ...recentQuotes.isEmpty
                  ? [Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.receipt, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No quotes yet',
                            style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )]
                  : recentQuotes.map((quote) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF00C48C).withOpacity(0.1),
                            radius: 20,
                            child: Text(
                              quote.providerName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF00C48C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(quote.providerName, 
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('\$${quote.price.toStringAsFixed(0)}',
                            style: TextStyle(color: const Color(0xFF3366FF), fontWeight: FontWeight.w500)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(quote.rating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      )).toList(),

              const SizedBox(height: 24),

              /// Ongoing Jobs Section
              const _SectionHeader(title: 'Current Job'),
              const SizedBox(height: 8),
              ongoingJobs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.work_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No ongoing jobs',
                            style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3366FF), Color(0xFF00C48C)],
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(ongoingJobs.first.category, 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          )),
                        subtitle: Text('Provider: ${recentQuotes.isEmpty ? 'Assigned' : recentQuotes.first.providerName}',
                          style: const TextStyle(color: Colors.white70)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('In Progress',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),

              const SizedBox(height: 24),

              /// Notifications Section
              const _SectionHeader(title: 'Notifications'),
              const SizedBox(height: 8),
              ..._notifications.take(3).map((n) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.white : const Color(0xFF3366FF).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: n.isRead ? Colors.grey.shade200 : const Color(0xFF3366FF).withOpacity(0.2),
                      ),
                    ),
                    child: _NotificationTile(
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
                    ),
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
  const _SummaryCard({
    required this.icon, 
    required this.label, 
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, 
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: color,
          )),
        const SizedBox(height: 4),
        Text(label, 
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          )),
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
          Text(title, 
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1F36),
            )),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap, 
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3366FF),
              ),
              child: Text(actionLabel!),
            ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUnread 
              ? const Color(0xFF3366FF).withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, 
          color: isUnread ? const Color(0xFF3366FF) : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(text, 
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          color: isUnread ? const Color(0xFF1A1F36) : Colors.grey.shade700,
        )),
      trailing: isUnread
          ? Container(
              width: 10, 
              height: 10, 
              decoration: BoxDecoration(
                color: const Color(0xFF00C48C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C48C).withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ))
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
      IconButton(
        onPressed: onTap, 
        icon: Icon(Icons.notifications_none, 
          color: count > 0 ? const Color(0xFF3366FF) : Colors.grey.shade600,
          size: 28,
        ),
      ),
      if (count > 0)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF00C48C),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C48C).withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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

    return Container(
      color: const Color(0xFFF8FAFF),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          ServiceRequest? request;
          Quote? quote;
          try { request = requestProvider.requests.firstWhere((r) => r.id == payment.requestId); } catch (_) { request = null; }
          try { quote = quoteProvider.quotes.firstWhere((q) => q.id == payment.quoteId); } catch (_) { quote = null; }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3366FF).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3366FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.payment, color: const Color(0xFF3366FF), size: 24),
              ),
              title: Text('\$${payment.amount.toStringAsFixed(2)}', 
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1A1F36),
                )),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const SizedBox(height: 4),
                  Text(request?.category ?? 'Service request',
                    style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text('Provider: ${quote?.providerName ?? 'Unknown'}', 
                    style: TextStyle(color: const Color(0xFF00C48C), fontSize: 12)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.createdAt.toLocal().toString().split(' ').first, 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
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
        return const Color(0xFFFFB800);
      case RequestStatus.quoted:
        return const Color(0xFF3366FF);
      case RequestStatus.accepted:
        return const Color(0xFF00C48C);
      case RequestStatus.completed:
        return const Color(0xFF00C48C);
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
      backgroundColor: const Color(0xFFF8FAFF),
      body: requestProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3366FF)))
          : requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No requests yet',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final List<Quote> quotes = quoteProvider.getQuotesForRequest(req.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3366FF).withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            req.status == RequestStatus.pending ? Icons.hourglass_empty :
                            req.status == RequestStatus.quoted ? Icons.receipt :
                            req.status == RequestStatus.accepted ? Icons.check_circle :
                            req.status == RequestStatus.completed ? Icons.done_all :
                            Icons.cancel,
                            color: _getStatusColor(req.status),
                            size: 24,
                          ),
                        ),
                        title: Text('${req.category} - ${req.location}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F36),
                          )),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(req.description,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_getStatusText(req.status),
                            style: TextStyle(
                              color: _getStatusColor(req.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                        ),
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => RequestDetailScreen(request: req, quotes: quotes)
                          )
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Create Request'),
        backgroundColor: const Color(0xFF3366FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1F36),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Container(
        color: const Color(0xFFF8FAFF),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: n.isRead ? Colors.grey.shade200 : const Color(0xFF3366FF).withOpacity(0.3),
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: n.isRead 
                        ? Colors.grey.shade100 
                        : const Color(0xFF3366FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    n.isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: n.isRead ? Colors.grey.shade600 : const Color(0xFF3366FF),
                  ),
                ),
                title: Text(n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                  )),
                subtitle: Text(n.message),
                trailing: n.isRead 
                    ? null 
                    : Container(
                        width: 8, 
                        height: 8, 
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C48C),
                          shape: BoxShape.circle,
                        ),
                      ),
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => NotificationDetailScreen(notification: n)
                  )
                ),
              ),
            );
          },
        ),
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
      appBar: AppBar(
        title: Text(notification.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1F36),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF8FAFF),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3366FF).withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3366FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications, 
                            color: Color(0xFF3366FF), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF4A4E69)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Received: ${_formatDate(notification.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}