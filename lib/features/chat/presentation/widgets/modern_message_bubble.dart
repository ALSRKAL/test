import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class ModernMessageBubble extends StatelessWidget {
  final String text;
  final bool isSent;
  final String time;
  final bool isRead;
  final String? senderAvatar;
  final bool showAvatar;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final VoidCallback? onReplyTap;
  final String? replyToText;
  final String? replyToSender;
  final bool highlighted;

  const ModernMessageBubble({
    super.key,
    required this.text,
    required this.isSent,
    required this.time,
    this.isRead = false,
    this.senderAvatar,
    this.showAvatar = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.onLongPress,
    this.onSwipeReply,
    this.onReplyTap,
    this.replyToText,
    this.replyToSender,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic border radius based on grouping
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isSent ? 20 : (isFirstInGroup ? 20 : 5)),
      topRight: Radius.circular(isSent ? (isFirstInGroup ? 20 : 5) : 20),
      bottomLeft: Radius.circular(isSent ? 20 : (isLastInGroup ? 20 : 5)),
      bottomRight: Radius.circular(isSent ? (isLastInGroup ? 20 : 5) : 20),
    );

    Widget bubbleContent = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSent ? AppColors.primaryGradient : null,
          color: isSent
              ? null
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        foregroundDecoration: highlighted
            ? BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.4), // Clear Green
                borderRadius: borderRadius,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply Context
            if (replyToText != null)
              GestureDetector(
                onTap: onReplyTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      right: BorderSide(
                        color: isSent
                            ? Colors.white.withOpacity(0.5)
                            : AppColors.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replyToSender ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSent
                              ? Colors.white.withOpacity(0.9)
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        replyToText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSent
                              ? Colors.white.withOpacity(0.7)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Message Text
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isSent
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),

            const SizedBox(height: 4),

            // Time & Read Status
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSent
                        ? Colors.white.withOpacity(0.7)
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isRead
                        ? const Color(0xFF40C4FF) // Bright Blue (WhatsApp-like)
                        : Colors.white.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    // Swipe to Reply Wrapper
    if (onSwipeReply != null) {
      return Dismissible(
        key: UniqueKey(),
        direction: isSent
            ? DismissDirection
                  .endToStart // Swipe Left for sent messages
            : DismissDirection.startToEnd, // Swipe Right for received messages
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.2,
          DismissDirection.endToStart: 0.2,
        },
        confirmDismiss: (direction) async {
          onSwipeReply!();
          return false; // Don't actually dismiss
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          color: Colors.transparent,
          child: Icon(
            Icons.reply_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 28,
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.transparent,
          child: Icon(
            Icons.reply_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 28,
          ),
        ),
        child: _buildBubbleLayout(bubbleContent),
      );
    }

    return _buildBubbleLayout(bubbleContent);
  }

  Widget _buildBubbleLayout(Widget bubbleContent) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInGroup ? AppSpacing.md : 2,
        left: isSent ? 0 : 0,
        right: isSent ? 0 : 0,
      ),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            if (showAvatar && senderAvatar != null)
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(senderAvatar!),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],

          Flexible(child: bubbleContent),

          if (isSent) ...[
            const SizedBox(width: 8),
            // Placeholder for alignment symmetry if needed, or status icons outside bubble
          ],
        ],
      ),
    );
  }
}
