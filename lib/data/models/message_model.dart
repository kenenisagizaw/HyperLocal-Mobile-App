class Message {
	final String id;
	final String senderId;
	final String receiverId;
	final String content;
	final DateTime createdAt;
	bool isRead;

	Message({
		required this.id,
		required this.senderId,
		required this.receiverId,
		required this.content,
		required this.createdAt,
		this.isRead = false,
	});
}

