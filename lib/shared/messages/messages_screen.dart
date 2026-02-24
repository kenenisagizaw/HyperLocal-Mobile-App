import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_directory_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/provider_directory_provider.dart';
import '../../providers/quote_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProviderDirectoryProvider>().loadProviders(),
    );
    Future.microtask(
      () => context.read<CustomerDirectoryProvider>().loadCustomers(),
    );
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
      separatorBuilder: (_, __) => const Divider(height: 16),
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

    final threadMessages =
        messageProvider.messages
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
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
    final rating = isProvider
        ? _calculateProviderRating(quoteProvider, user.id)
        : null;
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
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
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
            _DetailRow(icon: Icons.phone, label: 'Phone', value: user.phone),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.email,
              label: 'Email',
              value: user.email ?? 'Not shared yet',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on,
              label: isProvider ? 'Location' : 'Address',
              value: isProvider
                  ? (user.location ?? 'Not shared yet')
                  : (user.address ?? 'Not shared yet'),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.social_distance,
              label: 'Distance',
              value: distanceKm == null
                  ? 'Not available'
                  : '${distanceKm.toStringAsFixed(1)} km',
            ),
            if (isProvider) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.verified,
                label: 'Verified',
                value: user.isVerified ? 'Yes' : 'No',
              ),
              if ((user.bio ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.info_outline,
                  label: 'Bio',
                  value: user.bio!,
                ),
              ],
            ],
            if (hasLocation) ...[
              const SizedBox(height: 16),
              const Text(
                'Location on Map',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(user.latitude!, user.longitude!),
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
                          point: LatLng(user.latitude!, user.longitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
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
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.nameFallback,
    this.radius = 20,
  });

  final UserModel? user;
  final String nameFallback;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imagePath = user?.profilePicture;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final initials = _getInitials(user?.name ?? nameFallback);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
      child: hasImage
          ? null
          : Text(
              initials,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

List<_ConversationSummary> _buildConversations(
  List<Message> messages,
  String currentUserId,
) {
  final Map<String, List<Message>> threads = {};

  for (final message in messages) {
    if (message.senderId != currentUserId &&
        message.receiverId != currentUserId) {
      continue;
    }

    final otherId = message.senderId == currentUserId
        ? message.receiverId
        : message.senderId;
    threads.putIfAbsent(otherId, () => []).add(message);
  }

  final List<_ConversationSummary> summaries = [];

  threads.forEach((otherId, threadMessages) {
    threadMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final lastMessage = threadMessages.last;
    final unreadCount = threadMessages
        .where(
          (m) =>
              m.receiverId == currentUserId &&
              m.senderId == otherId &&
              !m.isRead,
        )
        .length;

    summaries.add(
      _ConversationSummary(
        otherUserId: otherId,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      ),
    );
  });

  summaries.sort(
    (a, b) => b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt),
  );
  return summaries;
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
  return userId;
}

UserModel? _resolveUser(
  String userId,
  ProviderDirectoryProvider providerDirectory,
  CustomerDirectoryProvider customerDirectory,
) {
  final provider = providerDirectory.getProviderById(userId);
  if (provider != null) {
    return provider;
  }
  final customer = customerDirectory.getCustomerById(userId);
  if (customer != null) {
    return customer;
  }
  return null;
}

String _formatMessageTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }
  return '${difference.inDays}d';
}

String _getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'U';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

double? _calculateProviderRating(
  QuoteProvider quoteProvider,
  String providerId,
) {
  final providerQuotes = quoteProvider.quotes
      .where((q) => q.providerId == providerId)
      .toList();
  if (providerQuotes.isEmpty) {
    return null;
  }
  final total = providerQuotes.fold<double>(0, (sum, q) => sum + q.rating);
  return total / providerQuotes.length;
}

double? _calculateDistanceKm(UserModel? from, UserModel to) {
  if (from?.latitude == null ||
      from?.longitude == null ||
      to.latitude == null ||
      to.longitude == null) {
    return null;
  }

  const earthRadiusKm = 6371.0;
  final lat1 = _toRadians(from!.latitude!);
  final lon1 = _toRadians(from.longitude!);
  final lat2 = _toRadians(to.latitude!);
  final lon2 = _toRadians(to.longitude!);
  final dLat = lat2 - lat1;
  final dLon = lon2 - lon1;

  final a =
      pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degree) => degree * (pi / 180.0);
