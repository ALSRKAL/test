import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Conversation> getOrCreateConversation(String participantId);
  Future<List<Conversation>> getConversations();
  Future<Conversation> getConversation(String conversationId);
  Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String? type,
    Map<String, dynamic>? attachment,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToSenderName,
  });
  Future<void> markAsRead(String conversationId);
  Future<void> deleteMessage(String messageId);
  Future<Map<String, dynamic>> getUnreadCount();
  Future<List<Message>> searchMessages(String query, {String? conversationId});
}
