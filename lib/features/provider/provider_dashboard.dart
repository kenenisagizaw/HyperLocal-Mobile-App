import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../data/models/quote_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import '../customer/providers/customer_directory_provider.dart';
import '../customer/providers/quote_provider.dart';
import '../customer/providers/request_provider.dart';
import '../messages/messages_screen.dart';
import '../reviews/providers/review_provider.dart';
import '../profile/profile_screen.dart';
import 'quote_sent_screen.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _currentIndex = 0;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);

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
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _primaryBlue,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedIconTheme: const IconThemeData(size: 26),
            unselectedIconTheme: const IconThemeData(size: 24),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: 'Jobs'),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money_rounded),
                label: 'Quotes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_rounded),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
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

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);
  static const _gradientStart = Color(0xFF2563EB);
  static const _gradientEnd = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RequestProvider>().loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final quoteProvider = context.watch<QuoteProvider>();
    final reviewProvider = context.watch<ReviewProvider>();

    final currentUser = authProvider.currentUser;
    final providerName = currentUser?.name ?? 'Provider';
    final providerQuotes = currentUser?.id == null
        ? <Quote>[]
        : quoteProvider.quotes
              .where((q) => q.providerId == currentUser!.id)
              .toList();
    final providerReviews = currentUser?.id == null
      ? <Review>[]
      : reviewProvider.getReviewsForProvider(currentUser!.id);
    final rating = providerReviews.isNotEmpty
      ? providerReviews
          .map((r) => r.rating)
          .fold<double>(0, (sum, value) => sum + value) /
        providerReviews.length
      : (providerQuotes.isEmpty
        ? 4.7
        : providerQuotes
            .map((q) => q.rating)
            .fold<double>(0, (sum, value) => sum + value) /
          providerQuotes.length);
    final unreadNotificationsCount = _notifications
        .where((n) => !n.isRead)
        .length;

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_gradientStart, _gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.transparent,
                            child: Text(
                              _getInitials(providerName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $providerName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Here's your business overview",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
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
                            builder: (_) => _NotificationListScreen(
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: _primaryBlue, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isOnline ? 'You\'re online' : 'You\'re offline',
                              style: TextStyle(
                                color: _isOnline ? _primaryGreen : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _isOnline,
                              onChanged: (value) => setState(() => _isOnline = value),
                              activeColor: _primaryGreen,
                              activeTrackColor: _primaryGreen.withOpacity(0.3),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(
                      icon: Icons.work_outline_rounded,
                      label: 'Active Jobs',
                      value: activeJobs.length.toString(),
                      gradientColors: const [_gradientStart, _gradientEnd],
                    ),
                    _SummaryCard(
                      icon: Icons.notifications_active_outlined,
                      label: 'New Requests',
                      value: newOpportunities.length.toString(),
                      gradientColors: const [_gradientEnd, _gradientStart],
                    ),
                    _SummaryCard(
                      icon: Icons.star_border_rounded,
                      label: 'Rating',
                      value: '${rating.toStringAsFixed(1)} ⭐',
                      gradientColors: const [_gradientStart, _gradientEnd],
                    ),
                    _SummaryCard(
                      icon: Icons.attach_money_rounded,
                      label: 'Today\'s Earnings',
                      value: '\$${earningsToday.toStringAsFixed(0)}',
                      gradientColors: const [_gradientEnd, _gradientStart],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Active Jobs',
                  actionLabel: 'View All',
                  onActionTap: () => widget.onNavigateToTab(1),
                ),
                const SizedBox(height: 12),
                if (activeJobsPreview.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: _cardDecoration(),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.work_outline_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No active jobs yet',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...activeJobsPreview.map(
                    (job) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: _cardDecoration(),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_gradientStart, _gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.build_rounded, color: Colors.white, size: 24),
                        ),
                        title: Text(
                          job.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Customer: ${job.customerId}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'In Progress',
                            style: TextStyle(
                              color: _primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 12),
                Container(
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _ActivityTile(
                        icon: Icons.notifications_outlined,
                        text: 'You received a new request',
                        time: '5 min ago',
                      ),
                      const Divider(height: 1, indent: 70),
                      _ActivityTile(
                        icon: Icons.check_circle_outline,
                        text: 'John accepted your quote',
                        time: '2 hours ago',
                      ),
                      const Divider(height: 1, indent: 70),
                      _ActivityTile(
                        icon: Icons.star_border_rounded,
                        text: 'New 5-star review added',
                        time: '1 day ago',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'This Week'),
                const SizedBox(height: 12),
                Container(
                  decoration: _cardDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WeeklyStat(
                          label: 'Jobs',
                          value: '${activeJobs.length + 2}',
                          icon: Icons.work_rounded,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _WeeklyStat(
                          label: 'Earnings',
                          value: '\$${(earningsToday + 200).toStringAsFixed(0)}',
                          icon: Icons.attach_money_rounded,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        _WeeklyStat(
                          label: 'Rating',
                          value: rating.toStringAsFixed(1),
                          icon: Icons.star_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  const _WeeklyStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.text,
    required this.time,
  });

  final IconData icon;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradientColors,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
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
  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Container(
                  decoration: BoxDecoration(
                    color: notification.isRead ? Colors.white : _primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: notification.isRead ? Colors.grey.shade200 : _primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notification.isRead ? Colors.grey.shade100 : _primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: notification.isRead ? Colors.grey.shade600 : _primaryBlue,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          _formatNotificationTime(notification.createdAt),
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
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
                  ),
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
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text(
                    notification.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatNotificationTime(notification.createdAt),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Text(notification.message, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
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
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.quoted:
        return Colors.purple;
      case RequestStatus.accepted:
        return _primaryBlue;
      case RequestStatus.completed:
        return _primaryGreen;
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No available jobs',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
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
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
                decoration: InputDecoration(
                  labelText: 'Category',
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
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.category_rounded, color: _primaryBlue),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance: ${_maxDistanceKm.toStringAsFixed(0)} km',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _primaryBlue,
                            inactiveTrackColor: _primaryBlue.withOpacity(0.2),
                            thumbColor: _primaryBlue,
                            overlayColor: _primaryBlue.withOpacity(0.1),
                            valueIndicatorColor: _primaryBlue,
                          ),
                          child: Slider(
                            value: _maxDistanceKm,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                            onChanged: (value) => setState(() => _maxDistanceKm = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs match your filters',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final req = filteredRequests[index];
                    final customer = customerDirectory.getCustomerById(
                      req.customerId,
                    );
                    final isDisabled =
                        req.status == RequestStatus.accepted ||
                        req.status == RequestStatus.completed ||
                        req.status == RequestStatus.cancelled;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                              builder: (_) => JobDetailScreen(
                                request: req,
                                customer: customer,
                                providerUser: providerUser,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _UserAvatar(
                                    name: customer?.name ?? 'Customer',
                                    imagePath: customer?.profilePicture,
                                    radius: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          req.location,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(req.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusText(req.status),
                                      style: TextStyle(
                                        color: _getStatusColor(req.status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                req.description,
                                style: TextStyle(color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer?.name ?? req.customerId,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.attach_money_rounded, size: 16, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        '\$${req.budget.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDisabled ? Colors.grey.shade400 : _primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
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
                                    child: const Text('Quote'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

double? _calculateDistanceKm(UserModel? from, double? toLat, double? toLng) {
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

  final a =
      pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
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

  static const _primaryBlue = Color(0xFF2563EB);
  static const _primaryGreen = Color(0xFF059669);

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitQuote() {
    final quoteProvider = context.read<QuoteProvider>();
    final requestProvider = context.read<RequestProvider>();
    final priceText = _priceController.text.trim();
    final notes = _notesController.text.trim();

    if (priceText.isEmpty || notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter price and notes to send a quote.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final providerUser = widget.providerUser;

    final quote = Quote(
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
    );

    quoteProvider.addQuote(quote);
    requestProvider.updateStatus(widget.request.id, RequestStatus.quoted);

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
    final request = widget.request;
    final customer = widget.customer;
    final hasLocation =
        request.locationLat != null && request.locationLng != null;

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
                  colors: [_primaryBlue.withOpacity(0.1), _primaryGreen.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.category,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.place_rounded,
                        label: request.location,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.attach_money_rounded,
                        label: '\$${request.budget.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                      color: Colors.black.withOpacity(0.05),
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
            _CustomerProfileCard(customer: customer),
            const SizedBox(height: 20),
            const Text(
              'Send Quote',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
                        borderSide: const BorderSide(color: _primaryBlue, width: 2),
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
                      labelText: 'Notes / Details',
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
                        borderSide: const BorderSide(color: _primaryBlue, width: 2),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          Text(label),
        ],
      ),
    );
  }
}

class _CustomerProfileCard extends StatelessWidget {
  const _CustomerProfileCard({required this.customer});

  final UserModel? customer;

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    if (customer == null) {
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              builder: (_) =>
                  _CustomerProfileDetailScreen(customer: customer!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _UserAvatar(
                name: customer!.name,
                imagePath: customer!.profilePicture,
                radius: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          customer!.phone,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer!.address ?? 'Address not set',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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

class _CustomerProfileDetailScreen extends StatelessWidget {
  const _CustomerProfileDetailScreen({required this.customer});

  final UserModel customer;

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final hasLocation = customer.latitude != null && customer.longitude != null;

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
                  colors: [_primaryBlue.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _UserAvatar(
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
            const SizedBox(height: 20),
            _InfoSection(
              title: 'Contact Information',
              children: [
                _InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: customer.phone),
                _InfoRow(icon: Icons.email_rounded, label: 'Email', value: customer.email ?? 'Not shared'),
                _InfoRow(icon: Icons.location_on_rounded, label: 'Address', value: customer.address ?? 'Not shared'),
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
                      color: Colors.black.withOpacity(0.05),
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

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

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
          child: Column(
            children: children,
          ),
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.imagePath, this.radius = 20});

  final String name;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final initials = _getInitials(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
      backgroundImage: hasImage ? FileImage(File(imagePath!)) : null,
      child: hasImage
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
                fontSize: radius * 0.5,
              ),
            ),
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
            Icon(Icons.attach_money_rounded, size: 80, color: Colors.grey.shade300),
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
                color: Colors.black.withOpacity(0.05),
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
                  _UserAvatar(
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: request?.status == RequestStatus.accepted
                                    ? _primaryGreen.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request == null
                                    ? 'Unknown'
                                    : _getQuoteStatus(request.status),
                                style: TextStyle(
                                  color: request?.status == RequestStatus.accepted
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
                            Icon(Icons.category_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              request?.category ?? 'Unknown',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              _formatNotificationTime(q.createdAt),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                  colors: [_primaryBlue.withOpacity(0.1), _primaryGreen.withOpacity(0.1)],
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _formatNotificationTime(quote.createdAt),
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
                    _DetailRow(
                      icon: Icons.work_outline_rounded,
                      label: 'Category',
                      value: request!.category,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Status',
                      value: _formatRequestStatus(request!.status),
                      valueColor: request!.status == RequestStatus.accepted
                          ? _primaryGreen
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.place_rounded,
                      label: 'Location',
                      value: request!.location,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
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
                      color: Colors.black.withOpacity(0.05),
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
            _CustomerProfileCard(customer: customer),
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
            color: const Color(0xFF2563EB).withOpacity(0.1),
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

// ------------------- Messages -------------------

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) => const MessagesScreen();
}