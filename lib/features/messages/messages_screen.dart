import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import '../customer/providers/customer_directory_provider.dart';
import '../customer/providers/provider_directory_provider.dart';
import '../customer/providers/quote_provider.dart';
import 'providers/message_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProviderDirectoryProvider>().loadProviders();
    context.read<CustomerDirectoryProvider>().loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final providerDirectory = context.watch<ProviderDirectoryProvider>();
    final customerDirectory = context.watch<CustomerDirectoryProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('No user logged in'));
    }

    final conversations = _buildConversations(
      messageProvider.messages,
      currentUser.id,
    );

    if (conversations.isEmpty) {
      return const Center(child: Text('No messages yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      separatorBuilder: (context, index) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final convo = conversations[index];
        final otherId = convo.otherUserId;
        final displayName = _resolveDisplayName(
          otherId,
          providerDirectory,
          customerDirectory,
        );

        final otherUser = _resolveUser(
          otherId,
          providerDirectory,
          customerDirectory,
        );

        return ListTile(
          leading: GestureDetector(
            onTap: () {
              if (otherUser == null) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileDetailScreen(user: otherUser),
                ),
              );
            },
            child: _UserAvatar(user: otherUser, nameFallback: displayName),
          ),
          title: Text(displayName),
          subtitle: Text(convo.lastMessage.content),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatMessageTime(convo.lastMessage.createdAt),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              if (convo.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    convo.unreadCount > 99
                        ? '99+'
                        : convo.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            messageProvider.markThreadAsRead(currentUser.id, otherId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessageThreadScreen(
                  otherUserId: otherId,
                  otherUserName: displayName,
                  otherUser: otherUser,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUser,
  });

  final String otherUserId;
  final String otherUserName;
  final UserModel? otherUser;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({
    required MessageProvider messageProvider,
    required String currentUserId,
  }) {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    messageProvider.addMessage(
      Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUserId,
        receiverId: widget.otherUserId,
        content: text,
        createdAt: DateTime.now(),
      ),
    );

    _controller.clear();
    Future.microtask(() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    final threadMessages = messageProvider.messages
        .where(
          (m) =>
              (m.senderId == currentUser.id &&
                  m.receiverId == widget.otherUserId) ||
              (m.senderId == widget.otherUserId &&
                  m.receiverId == currentUser.id),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        leading: widget.otherUser == null
            ? null
            : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfileDetailScreen(user: widget.otherUser!),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _UserAvatar(
                    user: widget.otherUser,
                    nameFallback: widget.otherUserName,
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: threadMessages.length,
              itemBuilder: (context, index) {
                final message = threadMessages[index];
                final isMine = message.senderId == currentUser.id;

                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMessageTime(message.createdAt),
                          style: TextStyle(
                            color: isMine ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(
                    messageProvider: messageProvider,
                    currentUserId: currentUser.id,
                  ),
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationSummary {
  _ConversationSummary({
    required this.otherUserId,
    required this.lastMessage,
    required this.unreadCount,
  });

  final String otherUserId;
  final Message lastMessage;
  final int unreadCount;
}

class UserProfileDetailScreen extends StatelessWidget {
  const UserProfileDetailScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isProvider = user.role == UserRole.provider;
    final authProvider = context.watch<AuthProvider>();
    final quoteProvider = context.watch<QuoteProvider>();
    final currentUser = authProvider.currentUser;
    final rating =
        isProvider ? _calculateProviderRating(quoteProvider, user.id) : null;
    final distanceKm = _calculateDistanceKm(currentUser, user);
    final hasLocation = user.latitude != null && user.longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'Provider Profile' : 'Customer Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UserAvatar(user: user, nameFallback: user.name, radius: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isProvider ? 'Service Provider' : 'Customer',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          if (rating != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if ((user.bio ?? '').isNotEmpty) ...[
              Text(
                user.bio!,
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 16),
            ],
            _InfoRow(label: 'Phone', value: user.phone),
            if (user.email != null)
              _InfoRow(label: 'Email', value: user.email!),
            if (user.location != null)
              _InfoRow(label: 'Location', value: user.location!),
            if (distanceKm != null)
              _InfoRow(
                label: 'Distance',
                value: '${distanceKm.toStringAsFixed(1)} km away',
              ),
            const SizedBox(height: 16),
            if (hasLocation)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(user.latitude!, user.longitude!),
                      initialZoom: 13,
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
                            point: LatLng(user.latitude!, user.longitude!),
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('No location available'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.nameFallback,
    this.radius = 22,
  });

  final UserModel? user;
  final String nameFallback;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = user?.profilePicture != null &&
        user!.profilePicture!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      backgroundImage: hasImage ? FileImage(File(user!.profilePicture!)) : null,
      child: hasImage
          ? null
          : Text(
              _getInitials(nameFallback),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
    );
  }
}

String _getInitials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

List<_ConversationSummary> _buildConversations(
  List<Message> messages,
  String currentUserId,
) {
  final Map<String, List<Message>> grouped = {};

  for (final msg in messages) {
    final otherUserId = msg.senderId == currentUserId
        ? msg.receiverId
        : msg.senderId;
    grouped.putIfAbsent(otherUserId, () => []).add(msg);
  }

  final summaries = grouped.entries.map((entry) {
    final sorted = entry.value..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unread = sorted
        .where(
          (m) => m.receiverId == currentUserId && !m.isRead,
        )
        .length;

    return _ConversationSummary(
      otherUserId: entry.key,
      lastMessage: sorted.first,
      unreadCount: unread,
    );
  }).toList();

  summaries.sort((a, b) => b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt));
  return summaries;
}

String _formatMessageTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  return '${difference.inDays}d';
}

String _resolveDisplayName(
  String userId,
  ProviderDirectoryProvider providerDirectory,
  CustomerDirectoryProvider customerDirectory,
) {
  final provider = providerDirectory.getProviderById(userId);
  if (provider != null) {
    return provider.name;
  }
  final customer = customerDirectory.getCustomerById(userId);
  if (customer != null) {
    return customer.name;
  }
  return 'Unknown User';
}

UserModel? _resolveUser(
  String userId,
  ProviderDirectoryProvider providerDirectory,
  CustomerDirectoryProvider customerDirectory,
) {
  return providerDirectory.getProviderById(userId) ??
      customerDirectory.getCustomerById(userId);
}

num? _calculateProviderRating(QuoteProvider quoteProvider, String providerId) {
  final providerQuotes =
      quoteProvider.quotes.where((q) => q.providerId == providerId).toList();
  if (providerQuotes.isEmpty) return null;
  final total = providerQuotes.fold<double>(
    0,
    (sum, q) => sum + q.rating,
  );
  return total / providerQuotes.length;
}

double? _calculateDistanceKm(UserModel? currentUser, UserModel otherUser) {
  if (currentUser == null ||
      currentUser.latitude == null ||
      currentUser.longitude == null ||
      otherUser.latitude == null ||
      otherUser.longitude == null) {
    return null;
  }

  const distance = Distance();
  return distance(
        LatLng(currentUser.latitude!, currentUser.longitude!),
        LatLng(otherUser.latitude!, otherUser.longitude!),
      ) /
      1000;
}
