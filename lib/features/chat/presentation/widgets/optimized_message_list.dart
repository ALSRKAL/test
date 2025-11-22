import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import 'modern_message_bubble.dart';

/// Optimized message list with pagination and lazy loading
class OptimizedMessageList extends StatefulWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final String currentUserId;
  final bool isTyping;
  final Function(String) onDeleteMessage;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final Function(Message) onSwipeReply;
  final Function(String)? onReplyTap;
  final String? highlightedMessageId;

  const OptimizedMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
    this.isTyping = false,
    required this.onDeleteMessage,
    required this.onLoadMore,
    required this.hasMore,
    required this.onSwipeReply,
    this.onReplyTap,
    this.highlightedMessageId,
  });

  @override
  State<OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<OptimizedMessageList> {
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final position = widget.scrollController.position;
    // Load more when user scrolls to top (within 200px)
    if (position.pixels < 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onLoadMore?.call();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      reverse: true, // Reverse order (newest at bottom)
      itemCount:
          widget.messages.length +
          (widget.isTyping ? 1 : 0) +
          (_isLoadingMore ? 1 : 0),
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        // Show typing indicator at bottom (index 0 in reverse list)
        if (widget.isTyping && index == 0) {
          return _TypingIndicator();
        }

        final adjustedIndex = widget.isTyping ? index - 1 : index;

        // Show loading indicator at top (last index in reverse list)
        if (_isLoadingMore && adjustedIndex == widget.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // If we are at the loading indicator index but loading is false, or out of bounds
        if (adjustedIndex >= widget.messages.length) {
          return const SizedBox.shrink();
        }

        final message = widget.messages[adjustedIndex];
        final isSent = message.senderId == widget.currentUserId;

        // Grouping Logic
        bool isFirstInGroup = true;
        bool isLastInGroup = true;
        bool showAvatar = !isSent;
        bool showDateHeader = false;

        // Check previous message (for first in group)
        if (adjustedIndex > 0) {
          final prevMessage = widget.messages[adjustedIndex - 1];
          if (prevMessage.senderId == message.senderId) {
            isFirstInGroup = false;
          }

          // Check date header
          if (!_isSameDay(prevMessage.createdAt, message.createdAt)) {
            showDateHeader = true;
            isFirstInGroup = true; // Reset grouping on new day
          }
        } else {
          showDateHeader = true; // Always show date for first message
        }

        // Check next message (for last in group)
        if (adjustedIndex < widget.messages.length - 1) {
          final nextMessage = widget.messages[adjustedIndex + 1];
          if (nextMessage.senderId == message.senderId) {
            isLastInGroup = false;
            showAvatar = false; // Don't show avatar if not last

            // Check if next message is on a different day
            if (!_isSameDay(message.createdAt, nextMessage.createdAt)) {
              isLastInGroup = true;
              showAvatar = !isSent;
            }
          }
        }

        return Column(
          children: [
            if (showDateHeader) _DateHeader(date: message.createdAt),
            ModernMessageBubble(
              key: ValueKey(
                '${message.id}_${message.id == widget.highlightedMessageId}',
              ),
              text: message.text,
              isSent: isSent,
              time: _formatTime(message.createdAt),
              isRead: message.isRead,
              senderAvatar: message.senderAvatar,
              showAvatar: showAvatar,
              isFirstInGroup: isFirstInGroup,
              isLastInGroup: isLastInGroup,
              replyToText: message.replyToMessageText,
              replyToSender: message.replyToSenderName,
              onReplyTap: message.replyToMessageId != null
                  ? () => widget.onReplyTap?.call(message.replyToMessageId!)
                  : null,
              onSwipeReply: widget.onSwipeReply != null
                  ? () => widget.onSwipeReply!(message)
                  : null,
              onLongPress: isSent
                  ? () {
                      // Show delete option
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'حذف الرسالة',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onDeleteMessage(message.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  : null,
              highlighted: message.id == widget.highlightedMessageId,
            ),
          ],
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);
    String text;

    if (difference.inDays == 0 && now.day == date.day) {
      text = 'اليوم';
    } else if (difference.inDays == 1 ||
        (difference.inDays == 0 && now.day != date.day)) {
      text = 'أمس';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: 48,
      ), // Indent for avatar space
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textSecondaryLight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
