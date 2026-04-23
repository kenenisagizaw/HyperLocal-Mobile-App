import 'message_model.dart';

class Conversation {
  Conversation({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
  });

  final String id;
  final List<String> participantIds;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participants = _extractParticipants(json);
    final lastMessage = _extractLastMessage(json);
    final updatedAt = _parseDate(json['updatedAt'] ?? json['lastMessageAt']);

    return Conversation(
      id: (json['id'] ?? json['_id'] ?? json['conversationId'] ?? '')
          .toString(),
      participantIds: participants,
      lastMessage: lastMessage,
      unreadCount: _parseInt(
        json['unreadCount'] ?? json['unread'] ?? json['unreadMessages'],
      ),
      updatedAt: updatedAt,
    );
  }

  String otherUserId(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId && id.isNotEmpty) {
        return id;
      }
    }

    final senderId = lastMessage?.senderId ?? '';
    if (senderId.isNotEmpty && senderId != currentUserId) {
      return senderId;
    }

    final receiverId = lastMessage?.receiverId ?? '';
    if (receiverId.isNotEmpty && receiverId != currentUserId) {
      return receiverId;
    }

    return participantIds.isNotEmpty ? participantIds.first : '';
  }

  static List<String> _extractParticipants(Map<String, dynamic> json) {
    final raw =
        json['participants'] ??
        json['members'] ??
        json['users'] ??
        json['user'];
    if (raw is List) {
      return raw
          .map((item) {
            if (item is Map) {
              final user = item['user'];
              if (user is Map) {
                return (user['id'] ?? user['_id'] ?? user['userId'] ?? '')
                    .toString();
              }
              return (item['id'] ?? item['_id'] ?? item['userId'] ?? '')
                  .toString();
            }
            return item.toString();
          })
          .where((id) => id.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Message? _extractLastMessage(Map<String, dynamic> json) {
    final data =
        json['lastMessage'] ?? json['message'] ?? json['latestMessage'];
    if (data is Map<String, dynamic>) {
      return Message.fromJson(data);
    }
    if (data is Map) {
      return Message.fromJson(data.cast<String, dynamic>());
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
