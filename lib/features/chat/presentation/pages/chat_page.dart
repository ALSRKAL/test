import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/chat_provider.dart';
import '../../domain/entities/message.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/optimized_message_list.dart';
import '../widgets/chat_shimmer.dart';
import '../../../../shared/widgets/chat/message_input.dart';

import '../../../../services/notification/notification_service.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  String? _actualConversationId;
  bool _isInitialLoad = true;
  Timer? _typingTimer;
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    // If we have a conversation ID, use it. Otherwise, get/create one.
    if (widget.conversationId.isNotEmpty && widget.conversationId != 'new') {
      _actualConversationId = widget.conversationId;
      // Set current conversation ID for notifications
      NotificationService().setCurrentConversationId(_actualConversationId);
    } else {
      try {
        final conversation = await ref
            .read(chatProvider.notifier)
            .getOrCreateConversation(widget.otherUserId);
        if (mounted) {
          setState(() {
            _actualConversationId = conversation.id;
          });
          // Set current conversation ID for notifications
          NotificationService().setCurrentConversationId(_actualConversationId);
        }
      } catch (e) {
        // Handle error
        print('Error getting conversation: $e');
      }
    }

    if (_actualConversationId != null && mounted) {
      await ref
          .read(chatProvider.notifier)
          .getMessages(_actualConversationId!, silent: false);

      // Smart Scroll Logic
      if (mounted) {
        _performSmartScroll();
      }
    }
  }

  void _performSmartScroll() {
    if (!_isInitialLoad) return;
    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }

    // With reverse: true, offset 0 is the bottom (newest message).
    // We just ensure we are at 0.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    // Clear current conversation ID for notifications
    NotificationService().setCurrentConversationId(null);

    // Stop typing immediately when leaving the page
    // Stop typing immediately when leaving the page
    if (_actualConversationId != null && mounted) {
      // We can't use ref.read() if the widget is already unmounted/disposed in some cases
      // But dispose() is called BEFORE unmount, so it should be safe usually.
      // However, to be safe against the error "Cannot use ref after the widget was disposed":
      try {
        final authState = ref.read(authProvider);
        final user = authState.user;
        if (user != null) {
          ref
              .read(chatProvider.notifier)
              .sendTyping(_actualConversationId!, user.id, user.name, false);
        }
      } catch (e) {
        // Ignore if ref is not available
      }
    }

    _scrollController.dispose();
    _typingTimer?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _handleTyping() {
    if (_actualConversationId == null) return;

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    // Send typing started
    ref
        .read(chatProvider.notifier)
        .sendTyping(_actualConversationId!, user.id, user.name, true);

    // Cancel previous timer
    _typingTimer?.cancel();

    // Set new timer to stop typing
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _actualConversationId != null) {
        try {
          final authState = ref.read(authProvider);
          final user = authState.user;
          if (user != null) {
            ref
                .read(chatProvider.notifier)
                .sendTyping(_actualConversationId!, user.id, user.name, false);
          }
        } catch (e) {
          // Ignore error if widget is disposed
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final chatState = ref.watch(chatProvider);
    final actualConversationId = _actualConversationId ?? widget.conversationId;

    final messages =
        actualConversationId.isNotEmpty && actualConversationId != 'new'
        ? chatState.getMessages(actualConversationId)
        : <Message>[];
    final isTyping = chatState.typingStatus[widget.otherUserId] ?? false;
    final isOnline = chatState.onlineStatus[widget.otherUserId] ?? false;
    final replyingToMessage = chatState.replyingToMessage;

    // Helper for AppBar participant info
    final otherParticipant = {
      'id': widget.otherUserId,
      'name': widget.otherUserName,
      'avatar': widget.otherUserAvatar,
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: otherParticipant['avatar'] != null
                  ? NetworkImage(otherParticipant['avatar']!)
                  : null,
              child: otherParticipant['avatar'] == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherParticipant['name']!,
                  style: const TextStyle(fontSize: 16),
                ),
                if (isOnline)
                  const Text(
                    'متصل الآن',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List - Optimized for performance
          Expanded(
            child: messages.isEmpty
                ? (chatState.isLoading || _isInitialLoad
                      ? const ChatShimmer()
                      : const Center(
                          child: Text(
                            'لا توجد رسائل بعد\nابدأ المحادثة الآن!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ))
                : OptimizedMessageList(
                    key: ValueKey('messages_$actualConversationId'),
                    messages: messages,
                    scrollController: _scrollController,
                    currentUserId: authState.user?.id ?? '',
                    isTyping: isTyping,
                    onDeleteMessage: (messageId) {
                      ref
                          .read(chatProvider.notifier)
                          .deleteMessage(messageId, actualConversationId);
                    },
                    onLoadMore: () {
                      ref
                          .read(chatProvider.notifier)
                          .loadMoreMessages(actualConversationId);
                    },
                    hasMore: messages.length >= 50 && messages.length % 50 == 0,
                    highlightedMessageId: _highlightedMessageId,
                    onSwipeReply: (message) {
                      ref.read(chatProvider.notifier).setReplyingTo(message);
                    },
                    onReplyTap: (replyId) async {
                      // Find index of the message
                      final index = messages.indexWhere((m) => m.id == replyId);
                      if (index != -1) {
                        // Highlight the message immediately so it's ready when rendered
                        setState(() {
                          _highlightedMessageId = replyId;
                        });

                        // Calculate approximate position
                        // We subtract a portion of the screen height to position the message
                        // in the middle/upper part of the screen rather than at the very bottom.
                        final screenHeight = MediaQuery.of(context).size.height;
                        final offset = (index * 80.0) - (screenHeight * 0.3);
                        final targetOffset = offset < 0 ? 0.0 : offset;

                        if (_scrollController.hasClients) {
                          // Wait for the scroll to finish
                          await _scrollController.animateTo(
                            targetOffset,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }

                        // Clear highlight after a delay (start timer AFTER scroll)
                        _highlightTimer?.cancel();
                        _highlightTimer = Timer(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _highlightedMessageId = null;
                            });
                          }
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'الرسالة غير موجودة في المحادثة الحالية',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: MessageInput(
              onSendMessage: (text) {
                // Stop typing immediately when sending
                _typingTimer?.cancel();
                if (actualConversationId.isNotEmpty &&
                    actualConversationId != 'new') {
                  ref
                      .read(chatProvider.notifier)
                      .sendTyping(
                        actualConversationId,
                        authState.user?.id ?? '',
                        authState.user?.name ?? '',
                        false,
                      );
                }

                ref
                    .read(chatProvider.notifier)
                    .sendMessage(
                      conversationId: actualConversationId,
                      receiverId: widget.otherUserId,
                      content: text,
                      currentUserId: authState.user?.id ?? '',
                      currentUserName: authState.user?.name ?? 'User',
                      currentUserAvatar: authState.user?.avatar,
                    );
              },
              replyingTo: replyingToMessage,
              onCancelReply: () {
                ref.read(chatProvider.notifier).cancelReply();
              },
              onTyping: _handleTyping,
            ),
          ),
        ],
      ),
    );
  }
}
