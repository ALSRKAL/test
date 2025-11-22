import 'dart:math' show min;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/chat_cache_datasource.dart';
import '../../../../services/socket/socket_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/sync/sync_service.dart';

/// Chat State
class ChatState {
  final bool isLoading;
  final String? error;
  final List<Conversation> conversations;
  final Map<String, List<Message>> messagesByConversation;
  final String? currentConversationId;
  final Map<String, bool> typingStatus;
  final Map<String, bool> onlineStatus;
  final bool isSending;
  final int totalUnreadCount;
  final Message? replyingToMessage;

  const ChatState({
    this.isLoading = false,
    this.error,
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.currentConversationId,
    this.typingStatus = const {},
    this.onlineStatus = const {},
    this.isSending = false,
    this.totalUnreadCount = 0,
    this.replyingToMessage,
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    List<Conversation>? conversations,
    Map<String, List<Message>>? messagesByConversation,
    String? currentConversationId,
    Map<String, bool>? typingStatus,
    Map<String, bool>? onlineStatus,
    bool? isSending,
    int? totalUnreadCount,
    Message? replyingToMessage,
    bool clearReply = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      typingStatus: typingStatus ?? this.typingStatus,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      isSending: isSending ?? this.isSending,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      replyingToMessage: clearReply
          ? null
          : (replyingToMessage ?? this.replyingToMessage),
    );
  }

  List<Message> getMessages(String conversationId) {
    return messagesByConversation[conversationId] ?? [];
  }
}

/// Chat Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository repository;
  final SocketService socketService;
  final ChatCacheDataSource cacheDataSource;

  ChatNotifier({
    required this.repository,
    required this.socketService,
    required this.cacheDataSource,
  }) : super(const ChatState()) {
    _initializeSocket();
    _setupSocketListeners();
    // Load cache in background without blocking
    Future.microtask(() => _loadCachedData());
  }

  /// Load cached data on startup for instant display
  Future<void> _loadCachedData() async {
    try {
      final cachedConversations = await cacheDataSource
          .getCachedConversations();
      if (cachedConversations.isNotEmpty && mounted) {
        state = state.copyWith(conversations: cachedConversations);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> _initializeSocket() async {
    // Connect socket immediately for real-time messaging
    if (!socketService.isConnected) {
      await socketService.connect();
      print('✅ Socket connected for real-time messaging');
    }
  }

  void _setupSocketListeners() {
    socketService.onNewMessage((data) {
      _handleNewMessage(data);
    });

    socketService.onTyping((data) {
      _handleTyping(data);
    });

    socketService.onStopTyping((data) {
      _handleStopTyping(data);
    });

    socketService.onUserOnline((data) {
      _handleUserOnline(data);
    });

    socketService.onUserOffline((data) {
      _handleUserOffline(data);
    });

    socketService.onMessagesRead((data) {
      _handleMessagesRead(data);
    });

    socketService.onMessageDeleted((data) {
      _handleMessageDeleted(data);
    });

    // Handle reconnection - Rejoin room
    socketService.onReconnect(() {
      print('🔄 Socket reconnected - Rejoining current conversation...');
      if (state.currentConversationId != null) {
        print('  Rejoining room: ${state.currentConversationId}');
        socketService.joinRoom(state.currentConversationId!);
      }
    });

    // Handle connection - Ensure in room
    socketService.onConnect(() {
      print('✅ Socket connected - Ensuring in conversation room...');
      if (state.currentConversationId != null) {
        print('  Joining room: ${state.currentConversationId}');
        socketService.joinRoom(state.currentConversationId!);
      }
    });
  }

  void setReplyingTo(Message message) {
    state = state.copyWith(replyingToMessage: message);
  }

  void cancelReply() {
    state = state.copyWith(clearReply: true);
  }

  void _handleNewMessage(dynamic data) {
    if (!mounted) return;

    print('📨 DEBUG: New message received via Socket');
    print('  Data: $data');

    // Force UI update even if data seems same, to ensure delivery
    // But we still check IDs to avoid duplication

    try {
      final conversationId = data['conversationId'] ?? '';
      final senderId = data['sender']?['_id'] ?? '';

      print('  ConversationId: $conversationId');
      print('  SenderId: $senderId');
      print('  Current conversation: ${state.currentConversationId}');

      final message = Message(
        id: data['_id'] ?? '',
        conversationId: conversationId,
        senderId: senderId,
        senderName: data['sender']?['name'] ?? '',
        senderAvatar: data['sender']?['avatar'],
        text: data['content'] ?? '',
        type: data['type'] ?? 'text',
        isRead: data['isRead'] ?? false,
        createdAt: DateTime.parse(
          data['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
        replyToMessageId: data['replyToMessageId'],
        replyToMessageText: data['replyToMessageText'],
        replyToSenderName: data['replyToSenderName'],
      );

      print('  Message: ${message.text}');
      print('  From: ${message.senderName}');

      final currentMessages = state.getMessages(conversationId);
      print('  Current messages count: ${currentMessages.length}');

      // Check if message already exists by ID (avoid duplicates)
      final messageExistsById = currentMessages.any((m) => m.id == message.id);
      if (messageExistsById) {
        print('  ⚠️ Message with same ID already exists, skipping');
        return;
      }

      // Check if message already exists by content and timestamp (for optimistic updates)
      // This prevents duplicates when the same message comes via Socket after optimistic update
      final messageExistsByContent = currentMessages.any(
        (m) =>
            m.text == message.text &&
            m.senderId == message.senderId &&
            m.createdAt.difference(message.createdAt).inSeconds.abs() < 5,
      );
      if (messageExistsByContent) {
        print(
          '  ⚠️ Message with same content and time already exists (optimistic update), skipping',
        );
        return;
      }

      // IMPORTANT: If user is in the same conversation, mark as read immediately
      final isInSameConversation =
          state.currentConversationId == conversationId;
      if (isInSameConversation) {
        print(
          '  📖 User is in same conversation - will mark as read automatically',
        );
      }

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByConversation,
      );
      // Prepend new message (Newest first)
      updatedMessages[conversationId] = [message, ...currentMessages];

      print(
        '  Updated messages count: ${updatedMessages[conversationId]?.length}',
      );

      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == conversationId) {
          return Conversation(
            id: conv.id,
            photographerId: conv.photographerId,
            photographerName: conv.photographerName,
            photographerAvatar: conv.photographerAvatar,
            clientId: conv.clientId,
            clientName: conv.clientName,
            clientAvatar: conv.clientAvatar,
            lastMessage: message.text,
            lastMessageTime: message.createdAt,
            unreadCount: conv.unreadCount + 1,
            isOnline: conv.isOnline,
            createdAt: conv.createdAt,
          );
        }
        return conv;
      }).toList();

      // IMPORTANT: Force state update to trigger UI rebuild
      state = state.copyWith(
        messagesByConversation: updatedMessages,
        conversations: updatedConversations,
        totalUnreadCount: state.totalUnreadCount + 1,
      );

      print('✅ DEBUG: State updated successfully - UI should rebuild now');
      print(
        '  Total messages in conversation: ${state.getMessages(conversationId).length}',
      );

      // IMPORTANT: If user is in the same conversation, mark as read immediately
      if (isInSameConversation && mounted) {
        print('  📖 Auto-marking message as read (user is in conversation)');
        // Mark as read after a short delay to ensure message is displayed first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && state.currentConversationId == conversationId) {
            markAsRead(conversationId);
          }
        });
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error in _handleNewMessage: $e');
      print('  StackTrace: $stackTrace');
    }
  }

  void _handleTyping(dynamic data) {
    if (!mounted) return;
    final userId = data['userId'] ?? '';
    final updatedTypingStatus = Map<String, bool>.from(state.typingStatus);
    updatedTypingStatus[userId] = true;
    state = state.copyWith(typingStatus: updatedTypingStatus);
  }

  void _handleStopTyping(dynamic data) {
    if (!mounted) return;
    final userId = data['userId'] ?? '';
    final updatedTypingStatus = Map<String, bool>.from(state.typingStatus);
    updatedTypingStatus[userId] = false;
    state = state.copyWith(typingStatus: updatedTypingStatus);
  }

  void _handleUserOnline(dynamic data) {
    if (!mounted) return;

    final userId = data['userId'] ?? '';
    final updatedOnlineStatus = Map<String, bool>.from(state.onlineStatus);
    updatedOnlineStatus[userId] = true;

    final updatedConversations = state.conversations.map((conv) {
      if (conv.photographerId == userId || conv.clientId == userId) {
        return Conversation(
          id: conv.id,
          photographerId: conv.photographerId,
          photographerName: conv.photographerName,
          photographerAvatar: conv.photographerAvatar,
          clientId: conv.clientId,
          clientName: conv.clientName,
          clientAvatar: conv.clientAvatar,
          lastMessage: conv.lastMessage,
          lastMessageTime: conv.lastMessageTime,
          unreadCount: conv.unreadCount,
          isOnline: true,
          createdAt: conv.createdAt,
        );
      }
      return conv;
    }).toList();

    state = state.copyWith(
      onlineStatus: updatedOnlineStatus,
      conversations: updatedConversations,
    );
  }

  void _handleUserOffline(dynamic data) {
    if (!mounted) return;

    final userId = data['userId'] ?? '';
    final updatedOnlineStatus = Map<String, bool>.from(state.onlineStatus);
    updatedOnlineStatus[userId] = false;

    final updatedConversations = state.conversations.map((conv) {
      if (conv.photographerId == userId || conv.clientId == userId) {
        return Conversation(
          id: conv.id,
          photographerId: conv.photographerId,
          photographerName: conv.photographerName,
          photographerAvatar: conv.photographerAvatar,
          clientId: conv.clientId,
          clientName: conv.clientName,
          clientAvatar: conv.clientAvatar,
          lastMessage: conv.lastMessage,
          lastMessageTime: conv.lastMessageTime,
          unreadCount: conv.unreadCount,
          isOnline: false,
          createdAt: conv.createdAt,
        );
      }
      return conv;
    }).toList();

    state = state.copyWith(
      onlineStatus: updatedOnlineStatus,
      conversations: updatedConversations,
    );
  }

  void _handleMessagesRead(dynamic data) {
    if (!mounted) return;

    print('📖 DEBUG: Messages read event received');
    print('  Data: $data');

    final conversationId = data['conversationId'] ?? '';
    final readBy = data['readBy']?.toString() ?? '';

    print('  ConversationId: $conversationId');
    print('  ReadBy: $readBy');
    print('  Current conversation: ${state.currentConversationId}');

    if (conversationId.isEmpty || readBy.isEmpty) {
      print('❌ Invalid data: conversationId or readBy is empty');
      return;
    }

    // Create a completely NEW map to force Riverpod to detect the change
    final updatedMessages = <String, List<Message>>{};

    // Copy all conversations
    state.messagesByConversation.forEach((key, value) {
      if (key == conversationId) {
        // Update this conversation's messages
        int updatedCount = 0;
        final newMessages = value.map((msg) {
          // Mark as read ONLY if:
          // 1. Message is not already read
          // 2. Message was NOT sent by the reader (readBy)
          // This means: mark messages sent TO the reader (from the other person)
          if (!msg.isRead && msg.senderId != readBy) {
            updatedCount++;
            print(
              '  📝 Marking message as read: ${msg.id.substring(0, min(8, msg.id.length))}... from ${msg.senderName}',
            );

            return Message(
              id: msg.id,
              conversationId: msg.conversationId,
              senderId: msg.senderId,
              senderName: msg.senderName,
              senderAvatar: msg.senderAvatar,
              text: msg.text,
              type: msg.type,
              isRead: true, // Mark as read
              createdAt: msg.createdAt,
              replyToMessageId: msg.replyToMessageId,
              replyToMessageText: msg.replyToMessageText,
              replyToSenderName: msg.replyToSenderName,
            );
          }
          return msg;
        }).toList();

        updatedMessages[key] = newMessages;
        print(
          '✅ DEBUG: Marked $updatedCount messages as read in conversation: $conversationId',
        );
        print('  ReadBy: $readBy - marked messages NOT sent by this user');
      } else {
        // Keep other conversations as is
        updatedMessages[key] = value;
      }
    });

    if (updatedMessages.containsKey(conversationId)) {
      // IMPORTANT: Create a NEW state object to force UI rebuild
      state = ChatState(
        isLoading: state.isLoading,
        error: state.error,
        conversations: state.conversations,
        messagesByConversation: updatedMessages, // NEW map
        currentConversationId: state.currentConversationId,
        typingStatus: state.typingStatus,
        onlineStatus: state.onlineStatus,
        isSending: state.isSending,
        totalUnreadCount: state.totalUnreadCount,
      );

      print('🔄 DEBUG: State updated - UI should rebuild now');
    } else {
      print('⚠️ Conversation not found in local state: $conversationId');
    }
  }

  void _handleMessageDeleted(dynamic data) {
    if (!mounted) return;

    final messageId = data['messageId'] ?? '';
    final conversationId = data['conversationId'] ?? '';

    final updatedMessages = Map<String, List<Message>>.from(
      state.messagesByConversation,
    );
    if (updatedMessages.containsKey(conversationId)) {
      updatedMessages[conversationId] = updatedMessages[conversationId]!
          .where((msg) => msg.id != messageId)
          .toList();
    }

    state = state.copyWith(messagesByConversation: updatedMessages);
  }

  Future<Conversation> getOrCreateConversation(String participantId) async {
    if (!mounted) throw Exception('Provider disposed');

    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversation = await repository.getOrCreateConversation(
        participantId,
      );

      if (!mounted) throw Exception('Provider disposed');

      final exists = state.conversations.any((c) => c.id == conversation.id);
      if (!exists) {
        state = state.copyWith(
          conversations: [...state.conversations, conversation],
        );
      }

      state = state.copyWith(
        isLoading: false,
        currentConversationId: conversation.id,
      );
      return conversation;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> getConversations() async {
    // Don't show loading if we have cached data
    final hasCache = state.conversations.isNotEmpty;
    if (!hasCache) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final conversations = await repository.getConversations();

      // Cache conversations for next time
      cacheDataSource.cacheConversations(conversations);

      if (mounted) {
        state = state.copyWith(isLoading: false, conversations: conversations);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: hasCache
              ? null
              : e.toString(), // Don't show error if we have cache
        );
      }
    }
  }

  Future<void> getMessages(String conversationId, {bool silent = true}) async {
    if (!mounted) return;

    // Set current conversation first
    // If not silent and no messages in RAM, set loading immediately to prevent flash
    final hasRamMessages =
        state.messagesByConversation[conversationId]?.isNotEmpty ?? false;
    if (!silent && !hasRamMessages) {
      state = state.copyWith(
        currentConversationId: conversationId,
        isLoading: true,
      );
    } else {
      state = state.copyWith(currentConversationId: conversationId);
    }

    // Join socket room immediately for real-time updates
    if (!socketService.isConnected) {
      await socketService.connect();
    }
    socketService.joinRoom(conversationId);

    // Try to load from cache first for instant display
    final cachedMessages = await cacheDataSource.getCachedMessages(
      conversationId,
    );
    if (cachedMessages.isNotEmpty && mounted) {
      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByConversation,
      );
      updatedMessages[conversationId] = cachedMessages;
      state = state.copyWith(messagesByConversation: updatedMessages);
    }

    // Check if we have any messages (cache or state)
    final hasMessages =
        cachedMessages.isNotEmpty ||
        (state.messagesByConversation[conversationId]?.isNotEmpty ?? false);

    // Only show loading if no messages and not silent
    if (!silent && !hasMessages) {
      state = state.copyWith(isLoading: true);
    }

    try {
      // Load messages from server in background
      // Always load page 1 (latest messages)
      final messages = await repository.getMessages(conversationId, page: 1);

      if (!mounted) return;

      // Cache messages for next time
      cacheDataSource.cacheMessages(conversationId, messages);

      // Reverse messages to be [Newest...Oldest] for UI
      final reversedMessages = messages.reversed.toList();

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByConversation,
      );
      updatedMessages[conversationId] = reversedMessages;

      state = state.copyWith(
        messagesByConversation: updatedMessages,
        isLoading: false,
        error: null,
      );

      // Mark as read after loading (non-blocking)
      if (mounted) {
        markAsRead(conversationId); // Don't await - run in background
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: silent
              ? null
              : e.toString(), // Don't show error in silent mode
        );
      }
    }
  }

  Future<void> loadMoreMessages(String conversationId) async {
    if (!mounted) return;

    final currentMessages = state.getMessages(conversationId);
    // If we have fewer than 50 messages, we probably have all of them.
    if (currentMessages.length < 50) return;

    // Calculate next page
    // Assuming limit is 50. If we have 50, we ask for page 2.
    // If we have 100, we ask for page 3.
    final page = (currentMessages.length / 50).ceil() + 1;

    try {
      final newMessages = await repository.getMessages(
        conversationId,
        page: page,
      );

      if (newMessages.isEmpty || !mounted) return;

      // Reverse new messages (older chunk) to be [Newest...Oldest]
      final reversedNewMessages = newMessages.reversed.toList();

      // Filter out duplicates just in case
      final existingIds = currentMessages.map((m) => m.id).toSet();
      final uniqueNewMessages = reversedNewMessages
          .where((m) => !existingIds.contains(m.id))
          .toList();

      if (uniqueNewMessages.isEmpty) return;

      final updatedMessages = Map<String, List<Message>>.from(
        state.messagesByConversation,
      );
      // Append older messages to the end
      updatedMessages[conversationId] = [
        ...currentMessages,
        ...uniqueNewMessages,
      ];

      state = state.copyWith(messagesByConversation: updatedMessages);
    } catch (e) {
      // Silently fail for pagination errors
      print('Error loading more messages: $e');
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatar,
    String? type,
  }) async {
    if (content.trim().isEmpty || !mounted) return;

    final replyTo = state.replyingToMessage;

    // Create optimistic message immediately with REAL user ID
    final optimisticMessage = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: currentUserId, // Use actual user ID
      senderName: currentUserName,
      senderAvatar: currentUserAvatar,
      text: content,
      type: type ?? 'text',
      isRead: false,
      createdAt: DateTime.now(),
      replyToMessageId: replyTo?.id,
      replyToMessageText: replyTo?.text,
      replyToSenderName: replyTo?.senderName,
    );

    // Clear reply state immediately
    if (replyTo != null) {
      state = state.copyWith(clearReply: true);
    }

    // Add message to UI immediately (Optimistic Update)
    final currentMessages = state.getMessages(conversationId);
    final updatedMessages = Map<String, List<Message>>.from(
      state.messagesByConversation,
    );
    // Prepend optimistic message (Newest first)
    updatedMessages[conversationId] = [optimisticMessage, ...currentMessages];

    // Add to cache immediately
    cacheDataSource.addMessageToCache(conversationId, optimisticMessage);

    final updatedConversations = state.conversations.map((conv) {
      if (conv.id == conversationId) {
        return Conversation(
          id: conv.id,
          photographerId: conv.photographerId,
          photographerName: conv.photographerName,
          photographerAvatar: conv.photographerAvatar,
          clientId: conv.clientId,
          clientName: conv.clientName,
          clientAvatar: conv.clientAvatar,
          lastMessage: content,
          lastMessageTime: DateTime.now(),
          unreadCount: conv.unreadCount,
          isOnline: conv.isOnline,
          createdAt: conv.createdAt,
        );
      }
      return conv;
    }).toList();

    state = state.copyWith(
      isSending: false, // Don't show loading
      messagesByConversation: updatedMessages,
      conversations: updatedConversations,
    );

    // Send message in background
    try {
      final syncService = SyncService();
      final isOnline = await syncService.isOnline();

      if (!isOnline) {
        print('⚠️ Device is offline, adding message to pending actions');
        await syncService.addPendingAction('send_message', {
          'conversationId': conversationId,
          'receiverId': receiverId,
          'content': content,
          'type': type,
          'replyToMessageId': replyTo?.id,
          'replyToMessageText': replyTo?.text,
          'replyToSenderName': replyTo?.senderName,
        });
        return;
      }

      // TODO: Update repository to accept reply fields
      // For now, we send as normal message but backend needs update
      // We will simulate it by sending extra data if repository allows,
      // or just proceed with optimistic update showing it correctly locally.

      final message = await repository.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        type: type,
        replyToMessageId: replyTo?.id,
        replyToMessageText: replyTo?.text,
        replyToSenderName: replyTo?.senderName,
      );

      if (!mounted) return;

      // Update the optimistic message with real ID only (keep everything else)
      final messages = state.getMessages(conversationId);
      final updatedMessagesReal = Map<String, List<Message>>.from(
        state.messagesByConversation,
      );

      // Find and update the optimistic message in place
      final messageIndex = messages.indexWhere(
        (m) => m.id == optimisticMessage.id,
      );
      if (messageIndex != -1) {
        // Create updated message with real ID but keep original senderId AND reply info
        final updatedMessage = Message(
          id: message.id, // Use real ID from server
          conversationId: message.conversationId,
          senderId: currentUserId, // Keep the original senderId we used
          senderName: currentUserName,
          senderAvatar: currentUserAvatar,
          text: message.text,
          type: message.type,
          isRead: message.isRead,
          createdAt: message.createdAt,
          replyToMessageId: replyTo?.id,
          replyToMessageText: replyTo?.text,
          replyToSenderName: replyTo?.senderName,
        );

        final updatedList = List<Message>.from(messages);
        updatedList[messageIndex] = updatedMessage;
        updatedMessagesReal[conversationId] = updatedList;
      } else {
        // If not found (shouldn't happen), just add it with correct senderId
        final updatedMessage = Message(
          id: message.id,
          conversationId: message.conversationId,
          senderId: currentUserId, // Use the same senderId
          senderName: currentUserName,
          senderAvatar: currentUserAvatar,
          text: message.text,
          type: message.type,
          isRead: message.isRead,
          createdAt: message.createdAt,
          replyToMessageId: replyTo?.id,
          replyToMessageText: replyTo?.text,
          replyToSenderName: replyTo?.senderName,
        );
        updatedMessagesReal[conversationId] = [...messages, updatedMessage];
      }

      state = state.copyWith(
        messagesByConversation: updatedMessagesReal,
        error: null,
      );
    } catch (e) {
      if (mounted) {
        // Remove optimistic message on error
        final messages = state.getMessages(conversationId);
        final updatedMessagesError = Map<String, List<Message>>.from(
          state.messagesByConversation,
        );
        updatedMessagesError[conversationId] = messages
            .where((m) => m.id != optimisticMessage.id)
            .toList();

        state = state.copyWith(
          messagesByConversation: updatedMessagesError,
          error: 'فشل إرسال الرسالة',
        );
      }
    }
  }

  void sendTyping(
    String conversationId,
    String userId,
    String userName,
    bool isTyping,
  ) {
    if (isTyping) {
      socketService.sendTyping(conversationId, userId, userName);
    } else {
      socketService.stopTyping(conversationId, userId);
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      print(
        '📖 DEBUG: Marking messages as read for conversation: $conversationId',
      );

      // Call API to mark as read (this will also emit socket event to sender)
      await repository.markAsRead(conversationId);

      print('✅ DEBUG: Messages marked as read successfully');

      // Update local state
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == conversationId) {
          return Conversation(
            id: conv.id,
            photographerId: conv.photographerId,
            photographerName: conv.photographerName,
            photographerAvatar: conv.photographerAvatar,
            clientId: conv.clientId,
            clientName: conv.clientName,
            clientAvatar: conv.clientAvatar,
            lastMessage: conv.lastMessage,
            lastMessageTime: conv.lastMessageTime,
            unreadCount: 0,
            isOnline: conv.isOnline,
            createdAt: conv.createdAt,
          );
        }
        return conv;
      }).toList();

      state = state.copyWith(conversations: updatedConversations);

      // Sync total unread count from server to be accurate
      await getUnreadCount();
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  Future<void> deleteMessage(String messageId, String conversationId) async {
    if (!mounted) return;

    print('🗑️ DEBUG: Starting delete for message: $messageId');

    // Get current messages
    final currentMessages = state.getMessages(conversationId);

    // Find the message to delete
    Message? messageToDelete;
    try {
      messageToDelete = currentMessages.firstWhere(
        (msg) => msg.id == messageId,
      );
      print('✅ DEBUG: Found message to delete');
    } catch (e) {
      // Message not found, nothing to delete
      print('❌ DEBUG: Message not found in UI');
      return;
    }

    // Optimistic delete - remove from UI and cache immediately
    final updatedMessages = Map<String, List<Message>>.from(
      state.messagesByConversation,
    );
    updatedMessages[conversationId] = currentMessages
        .where((msg) => msg.id != messageId)
        .toList();

    state = state.copyWith(messagesByConversation: updatedMessages);
    cacheDataSource.removeMessageFromCache(conversationId, messageId);
    print('✅ DEBUG: Removed from UI and cache');

    // Delete from backend
    try {
      print('📡 DEBUG: Calling backend delete API...');
      await repository.deleteMessage(messageId);
      print('✅ DEBUG: Backend delete successful');

      // Success - message already removed from UI
      if (!mounted) return;

      // Clear any previous errors
      state = state.copyWith(error: null);
    } catch (e) {
      print('❌ DEBUG: Backend delete failed: $e');

      if (!mounted) return;

      // Error - restore the message
      final restoredMessages = Map<String, List<Message>>.from(
        state.messagesByConversation,
      );
      final messages = List<Message>.from(
        restoredMessages[conversationId] ?? [],
      );

      // Find the correct position to restore the message
      final originalIndex = currentMessages.indexOf(messageToDelete);
      if (originalIndex != -1 && originalIndex <= messages.length) {
        messages.insert(originalIndex, messageToDelete);
        restoredMessages[conversationId] = messages;
      } else {
        // If position not found, add at the end
        messages.add(messageToDelete);
        restoredMessages[conversationId] = messages;
      }

      state = state.copyWith(
        messagesByConversation: restoredMessages,
        error: 'فشل حذف الرسالة: $e',
      );
    }
  }

  Future<void> getUnreadCount() async {
    try {
      final data = await repository.getUnreadCount();
      state = state.copyWith(totalUnreadCount: data['totalUnread'] ?? 0);
    } catch (e) {
      print('Error getting unread count: $e');
    }
  }

  /// تحديث عدد الرسائل غير المقروءة (من Socket.IO)
  void updateUnreadCount(int count) {
    state = state.copyWith(totalUnreadCount: count);
  }

  void leaveConversation() {
    if (!mounted) return;

    if (state.currentConversationId != null) {
      try {
        socketService.leaveRoom(state.currentConversationId!);
      } catch (e) {
        // Ignore socket errors on leave
      }
      state = state.copyWith(currentConversationId: null);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    socketService.removeAllListeners();
    super.dispose();
  }
}

/// Providers
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ApiClient();
  final remoteDataSource = ChatRemoteDataSourceImpl(apiClient: apiClient);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Singleton SocketService to ensure same instance across app
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

final chatCacheDataSourceProvider = Provider<ChatCacheDataSource>((ref) {
  return ChatCacheDataSource();
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final cacheDataSource = ref.watch(chatCacheDataSourceProvider);
  return ChatNotifier(
    repository: repository,
    socketService: socketService,
    cacheDataSource: cacheDataSource,
  );
});
