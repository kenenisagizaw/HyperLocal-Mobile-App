import 'package:flutter/material.dart';
import '../providers/websocket_provider.dart';
import '../../features/messages/providers/message_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/bookings/providers/booking_provider.dart';
import '../widgets/connection_status_indicator.dart';

/// Example screen demonstrating WebSocket real-time features
class WebSocketExampleScreen extends StatefulWidget {
  const WebSocketExampleScreen({super.key});

  @override
  State<WebSocketExampleScreen> createState() => _WebSocketExampleScreenState();
}

class _WebSocketExampleScreenState extends State<WebSocketExampleScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize WebSocket connections for all providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webSocketProvider = context.read<WebSocketProvider>();
      final messageProvider = context.read<MessageProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final bookingProvider = context.read<BookingProvider>();
      
      // Connect to WebSocket
      webSocketProvider.connect();
      
      // Initialize real-time listeners
      messageProvider.initializeWebSocket();
      notificationProvider.initializeWebSocket();
      bookingProvider.initializeWebSocket();
      
      // Join specific rooms for real-time updates
      webSocketProvider.joinRoom('user_room');
      webSocketProvider.subscribeToUserUpdates('current_user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Features'),
        actions: const [
          ConnectionStatusIndicator(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          const ConnectionStatusBanner(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatus(),
                  const SizedBox(height: 24),
                  _buildRealtimeFeatures(),
                  const SizedBox(height: 24),
                  _buildEventLog(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "reconnect",
            onPressed: () => context.read<WebSocketProvider>().connect(),
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "disconnect",
            onPressed: () => context.read<WebSocketProvider>().disconnect(),
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<WebSocketProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connection Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Status: ${provider.currentStatus.name}'),
                    const Spacer(),
                    RealtimeBadge(isRealtime: provider.isConnected),
                  ],
                ),
                if (provider.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last Error: ${provider.lastError}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealtimeFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              'Messages',
              'Real-time messaging with instant delivery',
              Icons.message,
              () => _showMessageExample(),
            ),
            _buildFeatureCard(
              'Notifications',
              'Push notifications for important updates',
              Icons.notifications,
              () => _showNotificationExample(),
            ),
            _buildFeatureCard(
              'Bookings',
              'Live booking status updates',
              Icons.calendar_today,
              () => _showBookingExample(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildEventLog() {
    return Consumer<WebSocketProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'WebSocket events will appear here...\n\n'
                      'Events include:\n'
                      '• New messages\n'
                      '• Notifications\n'
                      '• Booking updates\n'
                      '• Connection status changes',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessageExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Real-Time Messages'),
        content: const Text(
          'Messages are delivered instantly when:\n'
          '• A new message is received\n'
          '• Message status changes (read/unread)\n'
          '• Typing indicators\n'
          '• User comes online/offline',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Real-Time Notifications'),
        content: const Text(
          'Notifications are pushed instantly for:\n'
          '• New service requests\n'
          '• Quote updates\n'
          '• Booking confirmations\n'
          '• Payment status changes\n'
          '• Review notifications',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBookingExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Real-Time Bookings'),
        content: const Text(
          'Booking updates are live:\n'
          '• Status changes (confirmed, in-progress, completed)\n'
          '• Cancellations\n'
          '• Rescheduling\n'
          '• Provider location updates\n'
          '• Time remaining',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Integration helper for easy WebSocket setup
class WebSocketIntegrationHelper {
  static void initializeRealtimeFeatures(BuildContext context) {
    // Get all providers
    final webSocketProvider = context.read<WebSocketProvider>();
    final messageProvider = context.read<MessageProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final bookingProvider = context.read<BookingProvider>();
    
    // Connect to WebSocket
    webSocketProvider.connect();
    
    // Initialize real-time listeners
    messageProvider.initializeWebSocket();
    notificationProvider.initializeWebSocket();
    bookingProvider.initializeWebSocket();
    
    // Subscribe to relevant rooms
    webSocketProvider.joinRoom('general');
    webSocketProvider.subscribeToUserUpdates('current_user_id');
  }
  
  static void cleanupRealtimeFeatures(BuildContext context) {
    context.read<WebSocketProvider>().disconnect();
  }
}
