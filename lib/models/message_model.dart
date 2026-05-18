enum MessageRole { user, assistant, error }

class MessageModel {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  const MessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  bool get isUser => role == MessageRole.user;
}
