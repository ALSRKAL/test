import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Conversation> getOrCreateConversation(String participantId) async {
    try {
      return await remoteDataSource.getOrCreateConversation(participantId);
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      return await remoteDataSource.getConversations();
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  @override
  Future<Conversation> getConversation(String conversationId) async {
    try {
      return await remoteDataSource.getConversation(conversationId);
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      return await remoteDataSource.getMessages(
        conversationId,
        page: page,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String? type,
    Map<String, dynamic>? attachment,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToSenderName,
  }) async {
    try {
      return await remoteDataSource.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        type: type,
        attachment: attachment,
        replyToMessageId: replyToMessageId,
        replyToMessageText: replyToMessageText,
        replyToSenderName: replyToSenderName,
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      await remoteDataSource.markAsRead(conversationId);
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      return await remoteDataSource.getUnreadCount();
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<List<Message>> searchMessages(
    String query, {
    String? conversationId,
  }) async {
    try {
      return await remoteDataSource.searchMessages(
        query,
        conversationId: conversationId,
      );
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }
}
