import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/chat/presentation/providers/chat_provider.dart';

class ChatListSheet extends ConsumerStatefulWidget {
  const ChatListSheet({super.key});

  @override
  ConsumerState<ChatListSheet> createState() => _ChatListSheetState();
}

class _ChatListSheetState extends ConsumerState<ChatListSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final conversations = chatState.conversations;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المحادثات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (chatState.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد محادثات بعد',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ابدأ محادثة مع مصورة',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(chatProvider.notifier).getConversations();
                    },
                    child: ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];

                        final authState = ref.watch(authProvider);
                        final currentUserId = authState.user?.id ?? '';
                        final isPhotographer =
                            conv.photographerId == currentUserId;
                        final otherNameRaw = isPhotographer
                            ? conv.clientName
                            : conv.photographerName;
                        final otherName = otherNameRaw.isEmpty
                            ? 'مستخدم'
                            : otherNameRaw;
                        final otherAvatar = isPhotographer
                            ? conv.clientAvatar
                            : conv.photographerAvatar;
                        final otherId = isPhotographer
                            ? conv.clientId
                            : conv.photographerId;

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    otherAvatar != null &&
                                        otherAvatar.isNotEmpty
                                    ? NetworkImage(otherAvatar)
                                    : null,
                                child:
                                    otherAvatar == null || otherAvatar.isEmpty
                                    ? Text(
                                        otherName.isNotEmpty
                                            ? otherName[0].toUpperCase()
                                            : '?',
                                      )
                                    : null,
                              ),
                              if (conv.isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(otherName),
                          subtitle: Text(
                            conv.lastMessage ?? 'لا توجد رسائل',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (conv.lastMessageTime != null)
                                Text(
                                  _formatTime(conv.lastMessageTime!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (conv.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGradientStart,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    '${conv.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'conversationId': conv.id,
                                'otherUserId': otherId,
                                'otherUserName': otherName,
                                'otherUserAvatar': otherAvatar,
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
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
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
