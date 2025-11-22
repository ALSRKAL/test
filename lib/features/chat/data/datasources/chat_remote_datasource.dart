import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<ConversationModel> getOrCreateConversation(String participantId);
  Future<List<ConversationModel>> getConversations();
  Future<ConversationModel> getConversation(String conversationId);
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  });
  Future<MessageModel> sendMessage({
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
  Future<List<MessageModel>> searchMessages(
    String query, {
    String? conversationId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ConversationModel> getOrCreateConversation(
    String participantId,
  ) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.createConversation,
        data: {'participantId': participantId},
      );

      if (response.statusCode == 200 && response.data['success']) {
        return ConversationModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to create conversation');
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await apiClient.get(ApiEndpoints.conversations);

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ConversationModel.fromJson(json)).toList();
      }

      throw Exception('Failed to load conversations');
    } catch (e) {
      throw Exception('Error loading conversations: $e');
    }
  }

  @override
  Future<ConversationModel> getConversation(String conversationId) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.conversations}/$conversationId',
      );

      if (response.statusCode == 200 && response.data['success']) {
        return ConversationModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to load conversation');
    } catch (e) {
      throw Exception('Error loading conversation: $e');
    }
  }

  @override
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.conversations}/$conversationId/messages',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MessageModel.fromJson(json)).toList();
      }

      throw Exception('Failed to load messages');
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage({
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
      final response = await apiClient.post(
        ApiEndpoints.sendMessage,
        data: {
          'conversationId': conversationId,
          'receiverId': receiverId,
          'content': content,
          if (type != null) 'type': type,
          if (attachment != null) 'attachment': attachment,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
          if (replyToMessageText != null)
            'replyToMessageText': replyToMessageText,
          if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
        },
      );

      if (response.statusCode == 201 && response.data['success']) {
        return MessageModel.fromJson(response.data['data']);
      }

      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      final response = await apiClient.put(
        '${ApiEndpoints.conversations}/$conversationId/read',
      );

      if (response.statusCode != 200 || !response.data['success']) {
        throw Exception('Failed to mark as read');
      }
    } catch (e) {
      throw Exception('Error marking as read: $e');
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      print(
        '🌐 DEBUG: Sending DELETE request to: ${ApiEndpoints.messages}/$messageId',
      );

      final response = await apiClient.delete(
        '${ApiEndpoints.messages}/$messageId',
      );

      print('📥 DEBUG: Delete response status: ${response.statusCode}');
      print('📥 DEBUG: Delete response data: ${response.data}');

      if (response.statusCode != 200 || !response.data['success']) {
        throw Exception('Failed to delete message: ${response.data}');
      }

      print('✅ DEBUG: Message deleted successfully from backend');
    } catch (e) {
      print('❌ DEBUG: Error in deleteMessage datasource: $e');
      throw Exception('Error deleting message: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await apiClient.get(ApiEndpoints.unreadCount);

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'];
      }

      throw Exception('Failed to get unread count');
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(
    String query, {
    String? conversationId,
  }) async {
    try {
      final response = await apiClient.get(
        '${ApiEndpoints.chat}/search',
        queryParameters: {
          'query': query,
          if (conversationId != null) 'conversationId': conversationId,
        },
      );

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MessageModel.fromJson(json)).toList();
      }

      throw Exception('Failed to search messages');
    } catch (e) {
      throw Exception('Error searching messages: $e');
    }
  }
}
