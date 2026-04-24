import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookings/booking_detail_screen.dart';
import '../../bookings/providers/booking_provider.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingProvider>().loadMyBookingsAllStatuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final allBookings = bookingProvider.bookings;

    final bookings = user == null
        ? <Booking>[]
        : allBookings.where((b) => b.providerId == user.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingProvider.isLoading && bookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : bookingProvider.errorMessage != null && bookings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(
                          bookingProvider.errorMessage ??
                              'Failed to load bookings',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<BookingProvider>()
                                .loadMyBookingsAllStatuses();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No bookings yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<BookingProvider>()
                          .loadMyBookingsAllStatuses(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingDetailScreen(
                                        bookingId: booking.id),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// 🔹 Top row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Booking • ${_shortId(booking.id)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        _StatusPill(status: booking.status),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    /// 🔹 Middle section
                                    const Text(
                                      'Service Booking',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      _statusLabel(booking.status),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    /// 🔹 Bottom row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(booking.createdAt),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey,
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
    );
  }

  String _shortId(String id) {
    if (id.isEmpty) return 'N/A';
    final end = id.length < 6 ? id.length : 6;
    return id.substring(0, end);
  }

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

/// 🔥 Status pill (Uber-style badge)
class _StatusPill extends StatelessWidget {
  final BookingStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status) {
      case BookingStatus.booked:
        bg = Colors.blue.withValues(alpha: 0.1);
        text = Colors.blue;
        break;
      case BookingStatus.inProgress:
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        break;
      case BookingStatus.completed:
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        break;
      case BookingStatus.cancelled:
        bg = Colors.red.withValues(alpha: 0.1);
        text = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}