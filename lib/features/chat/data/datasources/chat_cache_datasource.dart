import 'package:hive/hive.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

/// Local cache for chat data to improve performance
class ChatCacheDataSource {
  static const String _conversationsBox = 'conversations_cache';
  static const String _messagesBox = 'messages_cache';
  static const int _maxCachedMessages = 100; // Cache last 100 messages per conversation

  /// Get cached conversations
  Future<List<Conversation>> getCachedConversations() async {
    try {
      final box = await Hive.openBox<Map>(_conversationsBox);
      final conversations = <Conversation>[];
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          conversations.add(ConversationModel.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      
      // Sort by last message time
      conversations.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      return conversations;
    } catch (e) {
      return [];
    }
  }

  /// Cache conversations
  Future<void> cacheConversations(List<Conversation> conversations) async {
    try {
      final box = await Hive.openBox<Map>(_conversationsBox);
      await box.clear();
      
      for (var conversation in conversations) {
        final model = ConversationModel(
          id: conversation.id,
          photographerId: conversation.photographerId,
          photographerName: conversation.photographerName,
          photographerAvatar: conversation.photographerAvatar,
          clientId: conversation.clientId,
          clientName: conversation.clientName,
          clientAvatar: conversation.clientAvatar,
          lastMessage: conversation.lastMessage,
          lastMessageTime: conversation.lastMessageTime,
          unreadCount: conversation.unreadCount,
          isOnline: conversation.isOnline,
          createdAt: conversation.createdAt,
        );
        await box.put(conversation.id, model.toJson());
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Get cached messages for a conversation
  Future<List<Message>> getCachedMessages(String conversationId) async {
    try {
      final box = await Hive.openBox<Map>('${_messagesBox}_$conversationId');
      final messages = <Message>[];
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          messages.add(MessageModel.fromJson(Map<String, dynamic>.from(data)));
        }
      }
      
      // Sort by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      return messages;
    } catch (e) {
      return [];
    }
  }

  /// Cache messages for a conversation
  Future<void> cacheMessages(String conversationId, List<Message> messages) async {
    try {
      final box = await Hive.openBox<Map>('${_messagesBox}_$conversationId');
      await box.clear();
      
      // Only cache last N messages to save space
      final messagesToCache = messages.length > _maxCachedMessages
          ? messages.sublist(messages.length - _maxCachedMessages)
          : messages;
      
      for (var message in messagesToCache) {
        final model = MessageModel(
          id: message.id,
          conversationId: message.conversationId,
          senderId: message.senderId,
          senderName: message.senderName,
          senderAvatar: message.senderAvatar,
          text: message.text,
          type: message.type,
          isRead: message.isRead,
          createdAt: message.createdAt,
        );
        await box.put(message.id, model.toJson());
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Add single message to cache
  Future<void> addMessageToCache(String conversationId, Message message) async {
    try {
      final box = await Hive.openBox<Map>('${_messagesBox}_$conversationId');
      final model = MessageModel(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        senderName: message.senderName,
        senderAvatar: message.senderAvatar,
        text: message.text,
        type: message.type,
        isRead: message.isRead,
        createdAt: message.createdAt,
      );
      await box.put(message.id, model.toJson());
      
      // Clean old messages if cache is too large
      if (box.length > _maxCachedMessages) {
        final keys = box.keys.toList();
        await box.delete(keys.first);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Remove message from cache
  Future<void> removeMessageFromCache(String conversationId, String messageId) async {
    try {
      final box = await Hive.openBox<Map>('${_messagesBox}_$conversationId');
      await box.delete(messageId);
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      await Hive.deleteBoxFromDisk(_conversationsBox);
      // Note: Individual message boxes will be cleaned up on next access
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Clear cache for specific conversation
  Future<void> clearConversationCache(String conversationId) async {
    try {
      await Hive.deleteBoxFromDisk('${_messagesBox}_$conversationId');
    } catch (e) {
      // Ignore cache errors
    }
  }
}
