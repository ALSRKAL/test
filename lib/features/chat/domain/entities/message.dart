/// Message Entity
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final String? imageUrl;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  final String? replyToMessageId;
  final String? replyToMessageText;
  final String? replyToSenderName;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    this.imageUrl,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
    this.replyToMessageId,
    this.replyToMessageText,
    this.replyToSenderName,
  });
}
