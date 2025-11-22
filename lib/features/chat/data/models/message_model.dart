import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.text,
    super.imageUrl,
    super.isRead,
    required super.createdAt,
    super.senderAvatar,
    super.type,
    super.replyToMessageId,
    super.replyToMessageText,
    super.replyToSenderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      conversationId: json['conversation'] ?? '',
      senderId: json['sender']?['_id'] ?? json['sender'] ?? '',
      senderName: json['sender']?['name'] ?? '',
      senderAvatar: json['sender']?['avatar'],
      text: json['content'] ?? '',
      imageUrl: json['attachment']?['url'],
      type: json['type'] ?? 'text',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      replyToMessageId: json['replyToMessageId'],
      replyToMessageText: json['replyToMessageText'],
      replyToSenderName: json['replyToSenderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversation': conversationId,
      'sender': senderId,
      'content': text,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (imageUrl != null) 'attachment': {'url': imageUrl},
      'replyToMessageId': replyToMessageId,
      'replyToMessageText': replyToMessageText,
      'replyToSenderName': replyToSenderName,
    };
  }
}
