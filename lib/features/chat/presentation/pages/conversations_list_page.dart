import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/features/chat/presentation/pages/chat_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/common/custom_appbar.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../../shared/widgets/errors/empty_state.dart';
import '../../../../shared/widgets/common/offline_indicator.dart';
import '../providers/chat_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ConversationsListPage extends ConsumerStatefulWidget {
  const ConversationsListPage({super.key});

  @override
  ConsumerState<ConversationsListPage> createState() =>
      _ConversationsListPageState();
}

class _ConversationsListPageState extends ConsumerState<ConversationsListPage> {
  @override
  void initState() {
    super.initState();
    // Load conversations immediately without delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatProvider.notifier).getConversations();
        ref.read(chatProvider.notifier).getUnreadCount();
      }
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'المحادثات'),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: chatState.conversations.isEmpty && !chatState.isLoading
                ? const EmptyState(
                    message: 'لا توجد محادثات بعد',
                    icon: Icons.chat_bubble_outline,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(chatProvider.notifier).getConversations();
                    },
                    child: chatState.conversations.isEmpty
                        ? const Center(child: LoadingIndicator())
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              100,
                            ),
                            itemCount: chatState.conversations.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            // Performance optimization for long lists
                            cacheExtent: 500,
                            addAutomaticKeepAlives:
                                true, // Keep conversation tiles alive
                            addRepaintBoundaries: true,
                            itemBuilder: (context, index) {
                              final conversation =
                                  chatState.conversations[index];
                              final authState = ref.read(authProvider);
                              final currentUser = authState.user;

                              // Determine other participant
                              String otherUserId = '';
                              String otherUserName = '';
                              String? otherUserAvatar;

                              if (currentUser?.role == 'photographer') {
                                otherUserId = conversation.clientId;
                                otherUserName = conversation.clientName;
                                otherUserAvatar = conversation.clientAvatar;
                              } else {
                                otherUserId = conversation.photographerId;
                                otherUserName = conversation.photographerName;
                                otherUserAvatar =
                                    conversation.photographerAvatar;
                              }

                              return _ConversationTile(
                                conversation: conversation,
                                formatTime: _formatTime,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                        conversationId: conversation.id,
                                        otherUserId: otherUserId,
                                        otherUserName: otherUserName,
                                        otherUserAvatar: otherUserAvatar,
                                      ),
                                    ),
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
}

class _ConversationTile extends ConsumerWidget {
  final dynamic conversation;
  final String Function(DateTime?) formatTime;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.formatTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    // Determine other participant based on current user role
    String otherUserName = '';
    String? otherUserAvatar;

    if (currentUser?.role == 'photographer') {
      // If current user is photographer, show client info
      otherUserName = conversation.clientName ?? 'عميل';
      otherUserAvatar = conversation.clientAvatar;
    } else {
      // If current user is client, show photographer info
      otherUserName = conversation.photographerName ?? 'مصور';
      otherUserAvatar = conversation.photographerAvatar;
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: otherUserAvatar != null
                ? NetworkImage(otherUserAvatar)
                : null,
            child: otherUserAvatar == null && otherUserName.isNotEmpty
                ? Text(
                    otherUserName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (conversation.isOnline)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUserName,
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              formatTime(conversation.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: conversation.unreadCount > 0
                    ? AppColors.primaryGradientEnd
                    : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? 'لا توجد رسائل',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? AppColors.textPrimaryLight
                    : AppColors.textSecondaryLight,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
