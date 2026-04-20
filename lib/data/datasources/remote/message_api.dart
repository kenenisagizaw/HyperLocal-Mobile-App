import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_client.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

class MessageApi {
  MessageApi() : _dioFuture = ApiClient.create();

  final Future<Dio> _dioFuture;

  Future<List<Conversation>> getConversations() async {
    final dio = await _dioFuture;
    final response = await dio.get(ApiConstants.messageConversations);
    final map = _unwrapMap(response.data);
    final list = _extractList(map);
    return list
        .whereType<Map>()
        .map((item) => Conversation.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<MessagePage> getMessages({
    required String conversationId,
    int? take,
    String? cursor,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.get(
      '${ApiConstants.messageConversations}/$conversationId/messages',
      queryParameters: {
        if (take != null) 'take': take,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final map = _unwrapMap(response.data);
    final list = _extractList(map);
    final messages = list
        .whereType<Map>()
        .map((item) => Message.fromJson(item.cast<String, dynamic>()))
        .toList();
    final nextCursor = _extractCursor(map);
    return MessagePage(messages: messages, nextCursor: nextCursor);
  }

  Future<Message> sendMessage({
    required String otherUserId,
    required String content,
    List<String> attachmentPaths = const [],
  }) async {
    final dio = await _dioFuture;

    Response response;
    if (attachmentPaths.isNotEmpty) {
      final form = FormData.fromMap({
        'content': content,
        'attachments[]': await Future.wait(
          attachmentPaths.map((path) => MultipartFile.fromFile(path)),
        ),
      });
      response = await dio.post(
        '${ApiConstants.messageConversations}/$otherUserId/send',
        data: form,
      );
    } else {
      response = await dio.post(
        '${ApiConstants.messageConversations}/$otherUserId/send',
        data: {'content': content},
      );
    }

    final map = _unwrapMap(response.data);
    final messageMap = _extractMessageMap(map);
    return Message.fromJson(messageMap);
  }

  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) async {
    final dio = await _dioFuture;
    final response = await dio.patch(
      '${ApiConstants.messages}/$messageId',
      data: {'content': content},
    );
    final map = _unwrapMap(response.data);
    final messageMap = _extractMessageMap(map);
    return Message.fromJson(messageMap);
  }

  Future<void> deleteMessage({
    required String messageId,
    String scope = 'me',
  }) async {
    final dio = await _dioFuture;
    await dio.delete(
      '${ApiConstants.messages}/$messageId',
      queryParameters: {'scope': scope},
    );
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map['data'] is Map
            ? (map['data'] as Map).cast<String, dynamic>()
            : null;
    final direct = map['items'] ?? map['messages'] ?? map['conversations'];
    final list = direct is List
        ? direct
        : direct is Map
            ? (direct['items'] ??
                direct['messages'] ??
                direct['conversations'])
            : data?['items'] ?? data?['messages'] ?? data?['conversations'];
    if (list is List) {
      return list;
    }
    return const [];
  }

  String? _extractCursor(Map<String, dynamic> map) {
    final data = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map['data'] is Map
            ? (map['data'] as Map).cast<String, dynamic>()
            : null;
    final value = map['cursor'] ??
        map['nextCursor'] ??
        map['next'] ??
        data?['cursor'] ??
        data?['nextCursor'] ??
        data?['next'];
    if (value == null) {
      return null;
    }
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> _extractMessageMap(Map<String, dynamic> map) {
    final data = map['data'] ?? map['message'] ?? map['result'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    return map;
  }
}

class MessagePage {
  MessagePage({required this.messages, this.nextCursor});

  final List<Message> messages;
  final String? nextCursor;
}
