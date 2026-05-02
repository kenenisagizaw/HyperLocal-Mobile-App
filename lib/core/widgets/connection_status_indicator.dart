import 'package:flutter/material.dart';
import '../providers/websocket_provider.dart';
import '../services/websocket_service.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(provider.currentStatus),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getStatusIcon(provider.currentStatus),
              const SizedBox(width: 4),
              Text(
                _getStatusText(provider.currentStatus),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(WebSocketConnectionStatus status) {
    switch (status) {
      case WebSocketConnectionStatus.connected:
        return Colors.green;
      case WebSocketConnectionStatus.connecting:
      case WebSocketConnectionStatus.reconnecting:
        return Colors.orange;
      case WebSocketConnectionStatus.error:
        return Colors.red;
      case WebSocketConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(WebSocketConnectionStatus status) {
    switch (status) {
      case WebSocketConnectionStatus.connected:
        return Icons.wifi;
      case WebSocketConnectionStatus.connecting:
      case WebSocketConnectionStatus.reconnecting:
        return Icons.sync;
      case WebSocketConnectionStatus.error:
        return Icons.error_outline;
      case WebSocketConnectionStatus.disconnected:
        return Icons.wifi_off;
    }
  }

  String _getStatusText(WebSocketConnectionStatus status) {
    switch (status) {
      case WebSocketConnectionStatus.connected:
        return 'Connected';
      case WebSocketConnectionStatus.connecting:
        return 'Connecting...';
      case WebSocketConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case WebSocketConnectionStatus.error:
        return 'Error';
      case WebSocketConnectionStatus.disconnected:
        return 'Offline';
    }
  }
}

class RealtimeBadge extends StatelessWidget {
  final bool isRealtime;
  const RealtimeBadge({super.key, required this.isRealtime});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: provider.isConnected ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                provider.isConnected ? Icons.bolt : Icons.bolt_outlined,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 2),
              Text(
                provider.isConnected ? 'Live' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, provider, child) {
        if (provider.isConnected || provider.isConnecting) {
          return const SizedBox.shrink();
        }

        Color backgroundColor;
        String message;
        IconData icon;

        switch (provider.currentStatus) {
          case WebSocketConnectionStatus.error:
            backgroundColor = Colors.red.shade50;
            message = 'Connection error. Some features may not work properly.';
            icon = Icons.error_outline;
            break;
          case WebSocketConnectionStatus.reconnecting:
            backgroundColor = Colors.orange.shade50;
            message = 'Attempting to reconnect...';
            icon = Icons.sync;
            break;
          case WebSocketConnectionStatus.disconnected:
            backgroundColor = Colors.grey.shade200;
            message = 'Disconnected. Real-time updates unavailable.';
            icon = Icons.wifi_off;
            break;
          default:
            return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: backgroundColor,
          child: Row(
            children: [
              Icon(icon, color: backgroundColor.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: backgroundColor.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (provider.hasError)
                TextButton(
                  onPressed: () => provider.connect(),
                  child: Text(
                    'Retry',
                    style: TextStyle(color: backgroundColor.shade700),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
