import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/notifications/presentation/providers/notification_provider.dart';
import 'package:hajzy/features/notifications/presentation/widgets/notification_shimmer.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // تحميل الإشعارات
    Future.microtask(() {
      ref.read(notificationProvider.notifier).getNotifications();
    });

    // تهيئة timeago للعربية
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'mark_all_read') {
                  await ref.read(notificationProvider.notifier).markAllAsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديد جميع الإشعارات كمقروءة'),
                      ),
                    );
                  }
                } else if (value == 'delete_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('حذف جميع الإشعارات'),
                      content: const Text(
                        'هل أنت متأكد من حذف جميع الإشعارات؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await ref
                        .read(notificationProvider.notifier)
                        .deleteAllNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف جميع الإشعارات')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 8),
                      Text('تحديد الكل كمقروء'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف الكل', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: !state.isInitialized && state.isLoading
          ? const NotificationShimmer()
          : state.error != null && state.notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'حدث خطأ في تحميل الإشعارات',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(notificationProvider.notifier)
                            .getNotifications();
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : state.notifications.isEmpty && state.isInitialized
          ? _buildEmptyState()
          : state.isLoading
          ? Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(notificationProvider.notifier)
                        .getNotifications();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
                const Positioned.fill(child: Center(child: LoadingIndicator())),
              ],
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(notificationProvider.notifier)
                    .getNotifications();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'سيتم عرض الإشعارات هنا',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(notification) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        ref
            .read(notificationProvider.notifier)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الإشعار')));
      },
      child: InkWell(
        onTap: () {
          _handleNotificationTap(notification);
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('حذف الإشعار'),
              content: const Text('هل أنت متأكد من حذف هذا الإشعار؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(notificationProvider.notifier)
                        .deleteNotification(notification.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف الإشعار')),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey[200]!
                  : color.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeago.format(notification.createdAt, locale: 'ar'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_note;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'review':
        return Icons.star_outline;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return AppColors.warning;
      case 'message':
        return AppColors.primaryGradientStart;
      case 'review':
        return AppColors.gold;
      case 'payment':
        return AppColors.success;
      default:
        return AppColors.primaryGradientStart;
    }
  }

  void _handleNotificationTap(notification) {
    // تحديد الإشعار كمقروء
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // الانتقال إلى الصفحة المناسبة
    switch (notification.type) {
      case 'booking':
        Navigator.pushNamed(context, '/bookings-management');
        break;
      case 'message':
        if (notification.data != null &&
            notification.data!['conversationId'] != null) {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'conversationId': notification.data!['conversationId'],
              'otherUserId': notification.data!['senderId'],
              'otherUserName': notification.data!['senderName'],
              'otherUserAvatar': notification.data!['senderAvatar'],
            },
          );
        } else {
          Navigator.pushNamed(context, '/conversations');
        }
        break;
      case 'review':
        Navigator.pushNamed(context, '/reviews-section');
        break;
      case 'payment':
        Navigator.pushNamed(context, '/earnings-report');
        break;
      default:
        // تحديد الإشعار كمقروء عند فتح التفاصيل
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }

        // عرض محتوى الإشعار في نافذة منبثقة بتصميم محسن
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    notification.body,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} دقيقة';
      }
      return '${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
