import 'package:flutter/material.dart';

import '../data/models/message_model.dart';

class MessageProvider extends ChangeNotifier {
	final List<Message> _messages = [
		Message(
			id: 'm1',
			senderId: 'provider-1',
			receiverId: 'customer-1',
			content: 'Hi! I just sent a quote.',
			createdAt: DateTime.now().subtract(const Duration(hours: 3)),
		),
		Message(
			id: 'm2',
			senderId: 'provider-2',
			receiverId: 'customer-1',
			content: 'Can you share more details?',
			createdAt: DateTime.now().subtract(const Duration(hours: 1)),
		),
	];

	List<Message> get messages => List.unmodifiable(_messages);

	void addMessage(Message message) {
		_messages.add(message);
		notifyListeners();
	}

	int getUnreadCountForUser(String userId) {
		return _messages
				.where((m) => m.receiverId == userId && !m.isRead)
				.length;
	}

	void markMessageAsRead(String messageId) {
		final message = _messages.firstWhere((m) => m.id == messageId);
		if (!message.isRead) {
			message.isRead = true;
			notifyListeners();
		}
	}

	void markThreadAsRead(String currentUserId, String otherUserId) {
		bool updated = false;
		for (final message in _messages) {
			if (message.receiverId == currentUserId &&
					message.senderId == otherUserId &&
					!message.isRead) {
				message.isRead = true;
				updated = true;
			}
		}
		if (updated) {
			notifyListeners();
		}
	}
}

