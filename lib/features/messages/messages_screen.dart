import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/message_model.dart' as message_models;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser != null) {
        context.read<MessageProvider>().loadConversations();
      }
      context.read<ProviderDirectoryProvider>().loadProviders();
      context.read<CustomerDirectoryProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final providerDirectory = context.watch<ProviderDirectoryProvider>();
    final customerDirectory = context.watch<CustomerDirectoryProvider>();

    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('No user logged in')),
      );
    }

    final conversations = messageProvider.conversations;

    if (messageProvider.isLoading && conversations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (conversations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.green.shade200,
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => context.read<MessageProvider>().loadConversations(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final otherId = convo.otherUserId(currentUser.id);
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

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: GestureDetector(
                    onTap: () {
                      if (otherUser == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileDetailScreen(user: otherUser),
                        ),
                      );
                    },
                    child: _UserAvatar(
                      user: otherUser,
                      nameFallback: displayName,
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      convo.lastMessage?.content ?? 'No messages yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMessageTime(
                          convo.lastMessage?.createdAt ?? DateTime.now(),
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      if (convo.unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                    ],
                  ),
                  onTap: () {
                    messageProvider.markThreadAsRead(convo.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageThreadScreen(
                          conversationId: convo.id,
                          otherUserId: otherId,
                          otherUserName: displayName,
                          otherUser: otherUser,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({
    super.key,
    this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUser,
  });

  final String? conversationId;
  final String otherUserId;
  final String otherUserName;
  final UserModel? otherUser;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadOtherUserProfile();
      final authUser = context.read<AuthProvider>().currentUser;
      final messageProvider = context.read<MessageProvider>();

      if ((_conversationId == null || _conversationId!.isEmpty) &&
          authUser != null) {
        if (messageProvider.conversations.isEmpty) {
          await messageProvider.loadConversations();
        }
        String? existingId;
        for (final convo in messageProvider.conversations) {
          if (convo.otherUserId(authUser.id) == widget.otherUserId) {
            existingId = convo.id;
            break;
          }
        }
        if (existingId != null) {
          setState(() {
            _conversationId = existingId;
          });
        }
      }

      if (_conversationId == null || _conversationId!.isEmpty) {
        return;
      }
      await messageProvider.loadMessages(
        conversationId: _conversationId!,
        take: 20,
      );
    });
  }

  Future<void> _loadOtherUserProfile() async {
    if (widget.otherUser != null || widget.otherUserId.trim().isEmpty) {
      return;
    }
    final providerDirectory = context.read<ProviderDirectoryProvider>();
    final customerDirectory = context.read<CustomerDirectoryProvider>();

    final provider = providerDirectory.getProviderById(widget.otherUserId);
    if (provider != null) {
      return;
    }
    final customer = customerDirectory.getCustomerById(widget.otherUserId);
    if (customer != null) {
      return;
    }

    await Future.wait([
      providerDirectory.fetchProviderById(widget.otherUserId),
      customerDirectory.fetchCustomerById(widget.otherUserId),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({required MessageProvider messageProvider}) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    if (widget.otherUserId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send message: missing recipient.'),
        ),
      );
      return;
    }

    final sent = await messageProvider.sendMessage(
      otherUserId: widget.otherUserId,
      content: text,
      attachmentPaths: _pendingAttachments.map((file) => file.path).toList(),
    );
    if (!mounted) return;

    if (sent == null) {
      final error = messageProvider.errorMessage ?? 'Message failed to send.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if ((_conversationId == null || _conversationId!.isEmpty) &&
        sent.conversationId.isNotEmpty) {
      setState(() {
        _conversationId = sent.conversationId;
      });
      await messageProvider.loadMessages(
        conversationId: sent.conversationId,
        take: 20,
      );
    } else if (_conversationId != null && _conversationId!.isNotEmpty) {
      await messageProvider.loadMessages(
        conversationId: _conversationId!,
        take: 20,
      );
    }

    _controller.clear();
    _pendingAttachments.clear();
    if (mounted) {
      setState(() {});
    }
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

  Future<void> _pickMedia({required bool isVideo, required bool fromCamera}) async {
    XFile? file;
    if (isVideo) {
      file = await _picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
    } else {
      file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
    }
    if (file == null) return;
    setState(() {
      _pendingAttachments.add(file!);
    });
  }

  void _removePendingAttachment(XFile file) {
    setState(() {
      _pendingAttachments.remove(file);
    });
  }

  bool _isImagePath(String path) {
    final cleaned = path.toLowerCase().split('?').first;
    return cleaned.endsWith('.png') ||
        cleaned.endsWith('.jpg') ||
        cleaned.endsWith('.jpeg') ||
        cleaned.endsWith('.gif') ||
        cleaned.endsWith('.webp');
  }

  bool _isVideoPath(String path) {
    final cleaned = path.toLowerCase().split('?').first;
    return cleaned.endsWith('.mp4') ||
        cleaned.endsWith('.mov') ||
        cleaned.endsWith('.avi') ||
        cleaned.endsWith('.mkv') ||
        cleaned.endsWith('.3gp');
  }

  Widget _buildAttachmentGallery(List<String> attachments,
      {required bool isMine}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((path) {
        final isImage = _isImagePath(path);
        final isVideo = _isVideoPath(path);
        final isRemote =
            path.startsWith('http://') || path.startsWith('https://');
        if (isImage) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 90,
              child: isRemote
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover),
            ),
          );
        }
        if (isVideo) {
          return Container(
            width: 120,
            height: 90,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMine ? Colors.white24 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  color: isMine ? Colors.white : Colors.grey.shade700,
                ),
                const SizedBox(height: 6),
                Text(
                  'Video',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMine ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMine ? Colors.white24 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Attachment',
            style: TextStyle(
              fontSize: 12,
              color: isMine ? Colors.white : Colors.grey.shade700,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingAttachmentTile(XFile file) {
    final path = file.path;
    final isImage = _isImagePath(path);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 74,
            height: 74,
            color: Colors.grey.shade200,
            child: isImage
                ? Image.file(File(path), fit: BoxFit.cover)
                : const Icon(Icons.videocam, color: Colors.black54),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePendingAttachment(file),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    final conversationId = _conversationId ?? '';
    final threadMessages = conversationId.isEmpty
        ? <message_models.Message>[]
        : messageProvider.getMessages(conversationId);
    final nextCursor = conversationId.isEmpty
        ? null
        : messageProvider.getNextCursor(conversationId);
    final hasMore = nextCursor != null && nextCursor.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.otherUserName),
        centerTitle: true,
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: messageProvider.isLoading && threadMessages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (conversationId.isEmpty) {
                          return;
                        }
                        await messageProvider.loadMessages(
                          conversationId: conversationId,
                          take: 20,
                        );
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: threadMessages.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (hasMore && index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: OutlinedButton(
                                onPressed: () {
                                  messageProvider.loadMessages(
                                    conversationId: conversationId,
                                    take: 20,
                                    cursor: nextCursor,
                                  );
                                },
                                child: const Text('Load older messages'),
                              ),
                            );
                          }
                          final message =
                              threadMessages[index - (hasMore ? 1 : 0)];
                          final isMine = message.senderId == currentUser.id;

                          return Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                gradient: isMine
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF1E3A8A),
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.green.shade50,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white
                                          : const Color(0xFF1E3A8A),
                                      fontSize: 15,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (message.attachments.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildAttachmentGallery(
                                      message.attachments,
                                      isMine: isMine,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatMessageTime(message.createdAt),
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white70
                                          : Colors.grey.shade500,
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
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_pendingAttachments.isNotEmpty) ...[
                    SizedBox(
                      height: 74,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pendingAttachments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final file = _pendingAttachments[index];
                          return _buildPendingAttachmentTile(file);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.add_circle_outline),
                        onSelected: (value) {
                          if (value == 'camera_photo') {
                            _pickMedia(isVideo: false, fromCamera: true);
                          } else if (value == 'gallery_photo') {
                            _pickMedia(isVideo: false, fromCamera: false);
                          } else if (value == 'camera_video') {
                            _pickMedia(isVideo: true, fromCamera: true);
                          } else if (value == 'gallery_video') {
                            _pickMedia(isVideo: true, fromCamera: false);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'camera_photo',
                            child: Text('Take Photo'),
                          ),
                          const PopupMenuItem(
                            value: 'gallery_photo',
                            child: Text('Photo from Gallery'),
                          ),
                          const PopupMenuItem(
                            value: 'camera_video',
                            child: Text('Record Video'),
                          ),
                          const PopupMenuItem(
                            value: 'gallery_video',
                            child: Text('Video from Gallery'),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () =>
                              _sendMessage(messageProvider: messageProvider),
                          icon: const Icon(Icons.send, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isProvider ? 'Provider Profile' : 'Customer Profile'),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _UserAvatar(
                      user: user,
                      nameFallback: user.name,
                      radius: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isProvider ? 'Service Provider' : 'Customer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (rating != null) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bio Section
              if ((user.bio ?? '').isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'About',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Contact Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: '📞 Phone',
                      value: user.phone,
                      icon: Icons.phone,
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: '✉️ Email',
                        value: user.email!,
                        icon: Icons.email,
                      ),
                    ],
                    if (user.location != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: '📍 Location',
                        value: user.location!,
                        icon: Icons.location_on,
                      ),
                    ],
                    if (distanceKm != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: '📏 Distance',
                        value: '${distanceKm.toStringAsFixed(1)} km away',
                        icon: Icons.map,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Map Section
              if (hasLocation)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 50,
                        color: Colors.green.shade200,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No location available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
      ],
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
    final hasImage =
        user?.profilePicture != null && user!.profilePicture!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: hasImage
            ? FileImage(File(user!.profilePicture!))
            : null,
        child: hasImage
            ? null
            : Text(
                _getInitials(nameFallback),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: radius * 0.5,
                ),
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
  if (provider != null) return provider.name;
  final customer = customerDirectory.getCustomerById(userId);
  if (customer != null) return customer.name;
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
  final providerQuotes = quoteProvider.quotes
      .where((q) => q.providerId == providerId)
      .toList();
  if (providerQuotes.isEmpty) return null;
  final total = providerQuotes.fold<double>(0, (sum, q) => sum + q.rating);
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
