import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/features/notifications/presentation/providers/notification_provider.dart';

class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
          icon: const Icon(Icons.notifications_outlined, size: 28),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.getTextPrimary(context),
            hoverColor: AppColors.primaryGradientStart.withOpacity(0.1),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 5,
            right: 5,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.getSurface(context),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
