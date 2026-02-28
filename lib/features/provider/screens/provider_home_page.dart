import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/models/quote_model.dart';
import '../../../data/models/review_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/quote_provider.dart';
import '../../customer/providers/request_provider.dart';
import '../../reviews/providers/review_provider.dart';
import '../utils/formatters.dart';

class ProviderHomePage extends StatefulWidget {
  const ProviderHomePage({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'p1',
      title: 'New request received',
      message: 'A new request is available in your area.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    AppNotification(
      id: 'p2',
      title: 'Quote accepted',
      message: 'John accepted your quote.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
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
      appBar: AppBar(
        title: const Text('Home'),
      ),
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
                  children: [
                    Expanded(
                      child: Row(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $providerName 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Here's your business overview",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    NotificationBell(
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
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: _primaryBlue, size: 20),
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
                              _isOnline ? "You're online" : "You're offline",
                              style: TextStyle(
                                color:
                                    _isOnline ? _primaryGreen : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _isOnline,
                              onChanged: (value) =>
                                  setState(() => _isOnline = value),
                              activeThumbColor: _primaryGreen,
                              activeTrackColor:
                                  _primaryGreen.withValues(alpha: 0.3),
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
                // Fixed 2x2 Grid for Summary Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    SummaryCard(
                      icon: Icons.work_outline_rounded,
                      label: 'Active Jobs',
                      value: activeJobs.length.toString(),
                      gradientColors: const [_gradientStart, _gradientEnd],
                    ),
                    SummaryCard(
                      icon: Icons.notifications_active_outlined,
                      label: 'New Requests',
                      value: newOpportunities.length.toString(),
                      gradientColors: const [_gradientEnd, _gradientStart],
                    ),
                    SummaryCard(
                      icon: Icons.star_border_rounded,
                      label: 'Rating',
                      value: '${rating.toStringAsFixed(1)} ⭐',
                      gradientColors: const [_gradientStart, _gradientEnd],
                    ),
                    SummaryCard(
                      icon: Icons.attach_money_rounded,
                      label: "Today's Earnings",
                      value: '\$${earningsToday.toStringAsFixed(0)}',
                      gradientColors: const [_gradientEnd, _gradientStart],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SectionHeader(
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
                          Icon(Icons.work_outline_rounded,
                              size: 48, color: Colors.grey.shade300),
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
                          child: const Icon(Icons.build_rounded,
                              color: Colors.white, size: 24),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryGreen.withValues(alpha: 0.1),
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
                const SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 12),
                Container(
                  decoration: _cardDecoration(),
                  child: const Column(
                    children: [
                      ActivityTile(
                        icon: Icons.notifications_outlined,
                        text: 'You received a new request',
                        time: '5 min ago',
                      ),
                      Divider(height: 1, indent: 70),
                      ActivityTile(
                        icon: Icons.check_circle_outline,
                        text: 'John accepted your quote',
                        time: '2 hours ago',
                      ),
                      Divider(height: 1, indent: 70),
                      ActivityTile(
                        icon: Icons.star_border_rounded,
                        text: 'New 5-star review added',
                        time: '1 day ago',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'This Week'),
                const SizedBox(height: 12),
                Container(
                  decoration: _cardDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        WeeklyStat(
                          label: 'Jobs',
                          value: '${activeJobs.length + 2}',
                          icon: Icons.work_rounded,
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200),
                        WeeklyStat(
                          label: 'Earnings',
                          value:
                              '\$${(earningsToday + 200).toStringAsFixed(0)}',
                          icon: Icons.attach_money_rounded,
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade200),
                        WeeklyStat(
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
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class WeeklyStat extends StatelessWidget {
  const WeeklyStat({
    super.key,
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

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
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
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                Text(time,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
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
      padding: const EdgeInsets.all(14),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
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

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.count, required this.onTap});

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
            child:
                const Icon(Icons.notifications_none_rounded, color: Colors.black87),
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

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key, required this.notifications});

  final List<AppNotification> notifications;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 80, color: Colors.grey.shade300),
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
                    color: notification.isRead
                        ? Colors.white
                        : _primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: notification.isRead
                          ? Colors.grey.shade200
                          : _primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notification.isRead
                            ? Colors.grey.shade100
                            : _primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: notification.isRead
                            ? Colors.grey.shade600
                            : _primaryBlue,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          formatNotificationTime(notification.createdAt),
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400),
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
                  ),
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
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatNotificationTime(notification.createdAt),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Text(notification.message,
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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