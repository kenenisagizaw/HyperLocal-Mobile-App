import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/message_repository.dart';

class MessageProvider extends ChangeNotifier {
  MessageProvider({required this.repository});

  final MessageRepository repository;

  final List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messagesByConversation = {};
  final Map<String, String?> _nextCursorByConversation = {};
  bool _isLoading = false;
  String? errorMessage;
  int? lastStatusCode;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;

  List<Message> getMessages(String conversationId) {
    return List.unmodifiable(_messagesByConversation[conversationId] ?? []);
  }

  String? getNextCursor(String conversationId) {
    return _nextCursorByConversation[conversationId];
  }

  Future<void> loadConversations() async {
    _setLoading(true);
    _clearErrors();
    try {
      final result = await repository.fetchConversations();
      _conversations
        ..clear()
        ..addAll(result);
      _sortConversations();
    } on DioException catch (error) {
      _setError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Message>> loadMessages({
    required String conversationId,
    int? take,
    String? cursor,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final page = await repository.fetchMessages(
        conversationId: conversationId,
        take: take,
        cursor: cursor,
      );
      final existing = _messagesByConversation[conversationId] ?? [];
      if (cursor == null || cursor.isEmpty) {
        _messagesByConversation[conversationId] = page.messages;
      } else {
        _messagesByConversation[conversationId] = [
          ...existing,
          ...page.messages,
        ];
      }
      _nextCursorByConversation[conversationId] = page.nextCursor;
      _sortMessages(conversationId);
      return _messagesByConversation[conversationId] ?? const [];
    } on DioException catch (error) {
      _setError(error);
      return const [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Message?> sendMessage({
    required String otherUserId,
    required String content,
    List<String> attachmentPaths = const [],
  }) async {
    if (otherUserId.trim().isEmpty) {
      errorMessage = 'Unable to send message: missing recipient.';
      notifyListeners();
      return null;
    }
    _setLoading(true);
    _clearErrors();
    try {
      final message = await repository.sendMessage(
        otherUserId: otherUserId,
        content: content,
        attachmentPaths: attachmentPaths,
      );
      _upsertMessage(message);
      await loadConversations();
      return message;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Message?> editMessage({
    required String messageId,
    required String content,
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      final message = await repository.editMessage(
        messageId: messageId,
        content: content,
      );
      _upsertMessage(message);
      return message;
    } on DioException catch (error) {
      _setError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMessage({
    required String messageId,
    String scope = 'me',
  }) async {
    _setLoading(true);
    _clearErrors();
    try {
      await repository.deleteMessage(messageId: messageId, scope: scope);
      _removeMessage(messageId);
      return true;
    } on DioException catch (error) {
      _setError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  int getUnreadCountForUser(String userId) {
    int total = 0;
    for (final convo in _conversations) {
      if (convo.otherUserId(userId).isNotEmpty) {
        total += convo.unreadCount;
      }
    }
    return total;
  }

  void markThreadAsRead(String conversationId) {
    final messages = _messagesByConversation[conversationId];
    if (messages == null) {
      return;
    }
    bool updated = false;
    for (final message in messages) {
      if (!message.isRead) {
        message.isRead = true;
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void _upsertMessage(Message message) {
    final conversationId = message.conversationId;
    if (conversationId.isEmpty) {
      return;
    }
    final list = _messagesByConversation[conversationId] ?? [];
    final index = list.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      list[index] = message;
    } else {
      list.add(message);
    }
    _messagesByConversation[conversationId] = list;
    _sortMessages(conversationId);
    notifyListeners();
  }

  void _removeMessage(String messageId) {
    bool updated = false;
    for (final entry in _messagesByConversation.entries) {
      final list = entry.value;
      final index = list.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        list.removeAt(index);
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void _sortMessages(String conversationId) {
    final list = _messagesByConversation[conversationId];
    if (list == null) {
      return;
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      final aDate = a.updatedAt ?? a.lastMessage?.createdAt ?? DateTime(0);
      final bDate = b.updatedAt ?? b.lastMessage?.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearErrors() {
    errorMessage = null;
    lastStatusCode = null;
  }

  void _setError(DioException error) {
    lastStatusCode = error.response?.statusCode;
    errorMessage = _extractErrorMessage(error);
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return message.toString();
      }
    }
    return error.message;
  }
}
