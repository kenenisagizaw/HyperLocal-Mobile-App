import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/app_notification_model.dart';
import '../../data/models/service_request_model.dart';
import '../../data/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import '../bookings/booking_detail_screen.dart';
import '../customer/providers/customer_directory_provider.dart';
import '../customer/providers/provider_directory_provider.dart';
import '../customer/providers/request_provider.dart';
import '../customer/request_detail_screen.dart';
import '../messages/messages_screen.dart';
import '../messages/providers/message_provider.dart';
import '../provider/screens/job_detail_screen.dart';

Future<void> handleNotificationTap(
  BuildContext context,
  AppNotification notification, {
  bool openFallbackDetail = true,
}) async {
  final data = notification.data ?? const <String, dynamic>{};
  final event = _stringFromData(data, const ['event']);
  final type = notification.type ?? '';
  final normalizedEvent = (event.isNotEmpty ? event : type).toUpperCase();

  final bookingId = _stringFromData(data, const ['bookingId', 'booking_id']);
  if (bookingId.isNotEmpty) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(bookingId: bookingId),
      ),
    );
    return;
  }

  final authUser = context.read<AuthProvider>().currentUser;
  final requestId = _stringFromData(data, const [
    'requestId',
    'serviceRequestId',
    'service_request_id',
  ]);
  if (requestId.isNotEmpty) {
    final handled = await _openRequestForRole(
      context,
      requestId,
      authUser?.role,
    );
    if (handled) return;
  }

  final conversationId = _stringFromData(data, const [
    'conversationId',
    'threadId',
    'messageThreadId',
  ]);
  var otherUserId = _stringFromData(data, const [
    'otherUserId',
    'senderId',
    'fromUserId',
    'userId',
  ]);

  if (conversationId.isNotEmpty || otherUserId.isNotEmpty) {
    final messageProvider = context.read<MessageProvider>();
    if (messageProvider.conversations.isEmpty) {
      await messageProvider.loadConversations();
      if (!context.mounted) return;
    }

    if (otherUserId.isEmpty && conversationId.isNotEmpty && authUser != null) {
      for (final convo in messageProvider.conversations) {
        if (convo.id == conversationId) {
          otherUserId = convo.otherUserId(authUser.id);
          break;
        }
      }
    }

    if (otherUserId.isNotEmpty) {
      final providerDirectory = context.read<ProviderDirectoryProvider>();
      final customerDirectory = context.read<CustomerDirectoryProvider>();
      final otherUser =
          providerDirectory.getProviderById(otherUserId) ??
          customerDirectory.getCustomerById(otherUserId);

      var otherUserName = _stringFromData(data, const [
        'otherUserName',
        'senderName',
        'userName',
      ]);
      if (otherUserName.isEmpty) {
        otherUserName = otherUser?.name ?? 'Chat';
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessageThreadScreen(
            conversationId: conversationId.isEmpty ? null : conversationId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUser: otherUser,
          ),
        ),
      );
      return;
    }
  }

  if (normalizedEvent == 'QUOTE_RECEIVED' ||
      normalizedEvent == 'QUOTE_ACCEPTED' ||
      normalizedEvent == 'QUOTE_REJECTED') {
    final quoteRequestId = _stringFromData(data, const [
      'serviceRequestId',
      'requestId',
    ]);
    if (quoteRequestId.isNotEmpty) {
      final handled = await _openRequestForRole(
        context,
        quoteRequestId,
        authUser?.role,
      );
      if (handled) return;
    }
  }

  if (normalizedEvent == 'REVIEW_RECEIVED' ||
      normalizedEvent == 'JOB_STATUS_UPDATED') {
    final eventBookingId = _stringFromData(data, const ['bookingId']);
    if (eventBookingId.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: eventBookingId),
        ),
      );
      return;
    }
  }

  if (openFallbackDetail && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No action available for this notification.'),
      ),
    );
  }
}

ServiceRequest? _findRequest(List<ServiceRequest> requests, String id) {
  for (final request in requests) {
    if (request.id == id) {
      return request;
    }
  }
  return null;
}

String _stringFromData(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

Future<bool> _openRequestForRole(
  BuildContext context,
  String requestId,
  UserRole? role,
) async {
  final requestProvider = context.read<RequestProvider>();
  final request =
      _findRequest(requestProvider.requests, requestId) ??
      await requestProvider.fetchRequestById(requestId);
  if (!context.mounted || request == null) return false;

  if (role == UserRole.provider) {
    final authUser = context.read<AuthProvider>().currentUser;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          request: request,
          customer: null,
          providerUser: authUser,
        ),
      ),
    );
    return true;
  }

  if (role == UserRole.customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RequestDetailScreen(request: request, initialQuotes: const []),
      ),
    );
    return true;
  }

  return false;
}
