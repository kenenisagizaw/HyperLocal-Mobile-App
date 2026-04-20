import '../datasources/remote/message_api.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessageRepository {
  MessageRepository(this.api);

  final MessageApi api;

  Future<List<Conversation>> fetchConversations() {
    return api.getConversations();
  }

  Future<MessagePage> fetchMessages({
    required String conversationId,
    int? take,
    String? cursor,
  }) {
    return api.getMessages(
      conversationId: conversationId,
      take: take,
      cursor: cursor,
    );
  }

  Future<Message> sendMessage({
    required String otherUserId,
    required String content,
    List<String> attachmentPaths = const [],
  }) {
    return api.sendMessage(
      otherUserId: otherUserId,
      content: content,
      attachmentPaths: attachmentPaths,
    );
  }

  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) {
    return api.editMessage(messageId: messageId, content: content);
  }

  Future<void> deleteMessage({required String messageId, String scope = 'me'}) {
    return api.deleteMessage(messageId: messageId, scope: scope);
  }
}
