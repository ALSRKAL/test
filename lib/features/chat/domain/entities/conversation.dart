/// Conversation Entity
class Conversation {
  final String id;
  final String photographerId;
  final String photographerName;
  final String? photographerAvatar;
  final String clientId;
  final String clientName;
  final String? clientAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.photographerId,
    required this.photographerName,
    this.photographerAvatar,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.createdAt,
  });
}
