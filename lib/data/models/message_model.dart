class Message {
	final String id;
	final String conversationId;
	final String senderId;
	final String receiverId;
	final String content;
	final DateTime createdAt;
	final DateTime? updatedAt;
	final List<String> attachments;
	bool isRead;

	Message({
		required this.id,
		required this.conversationId,
		required this.senderId,
		required this.receiverId,
		required this.content,
		required this.createdAt,
		this.updatedAt,
		this.attachments = const [],
		this.isRead = false,
	});

	factory Message.fromJson(Map<String, dynamic> json) {
		final sender = json['sender'] is Map ? json['sender'] as Map : null;
		final receiver = json['receiver'] is Map ? json['receiver'] as Map : null;
		final convo =
				json['conversation'] is Map ? json['conversation'] as Map : null;

		return Message(
			id: (json['id'] ?? json['_id'] ?? '').toString(),
			conversationId: (json['conversationId'] ??
							convo?['id'] ??
							convo?['_id'] ??
							'')
					.toString(),
			senderId: (json['senderId'] ??
							json['authorId'] ??
							sender?['id'] ??
							sender?['_id'] ??
							sender?['userId'] ??
							'')
					.toString(),
			receiverId: (json['receiverId'] ??
							json['recipientId'] ??
							receiver?['id'] ??
							receiver?['_id'] ??
							receiver?['userId'] ??
							'')
					.toString(),
			content: (json['content'] ?? json['message'] ?? json['text'] ?? '')
					.toString(),
			createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
			updatedAt: _parseDate(json['updatedAt']),
			attachments: _parseAttachments(json['attachments'] ?? json['files']),
			isRead: json['isRead'] == true || json['read'] == true,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'conversationId': conversationId,
			'senderId': senderId,
			'receiverId': receiverId,
			'content': content,
			'createdAt': createdAt.toIso8601String(),
			'updatedAt': updatedAt?.toIso8601String(),
			'attachments': attachments,
			'isRead': isRead,
		};
	}

	static DateTime? _parseDate(dynamic value) {
		if (value == null) {
			return null;
		}
		return DateTime.tryParse(value.toString());
	}

	static List<String> _parseAttachments(dynamic value) {
		if (value is List) {
			return value
					.map((item) {
						if (item is Map) {
							return (item['url'] ?? item['path'] ?? '').toString();
						}
						return item.toString();
					})
					.where((entry) => entry.isNotEmpty)
					.toList();
		}
		return const [];
	}
}

