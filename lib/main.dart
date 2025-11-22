import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:developer' as developer;
import 'services/local_storage/hive_service.dart';
import 'services/cache/cache_manager.dart';
import 'services/ads/admob_service.dart';
import 'services/notification/notification_service.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'core/init/offline_init.dart';
import 'services/sync/sync_service.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة نظام الأوف لاين
  await OfflineInit.initialize();

  // Initialize date formatting for Arabic locale
  await initializeDateFormatting('ar', null);

  // Initialize timeago for Arabic locale
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Initialize services
  await _initializeServices();

  runApp(const ProviderScope(child: HajzyApp()));
}

/// Initialize all services
Future<void> _initializeServices() async {
  try {
    // Initialize Hive for local storage
    final hiveService = HiveService();
    await hiveService.initialize();

    // Initialize Cache Manager
    final cacheManager = CacheManager();
    await cacheManager.initialize();

    // Initialize AdMob
    final adMobService = AdMobService();
    await adMobService.initialize();

    // Initialize OneSignal with notification handler
    final notificationService = NotificationService();
    await notificationService.initialize(
      'db0f9546-9d0c-411d-a59a-e331483b0d98',
      onNotificationOpened: _handleNotificationOpened,
    );

    // Set handler for foreground notifications to update unread count
    notificationService.setNotificationReceivedHandler(
      _handleNotificationReceived,
    );

    // Initialize Socket.IO for real-time messaging
    await _initializeSocket();

    // Initialize Sync Service
    final syncService = SyncService();
    await syncService.initialize();

    developer.log('All services initialized successfully', name: 'Main');
  } catch (e) {
    developer.log('Error initializing services: $e', name: 'Main', error: e);
  }
}

/// Initialize Socket connection if user is logged in
/// NOTE: Socket will be connected automatically by auth_provider after login
/// or when loading saved session. We don't need to connect here.
Future<void> _initializeSocket() async {
  try {
    developer.log(
      'ℹ️ Socket will be initialized by auth_provider',
      name: 'Main',
    );
    // Socket connection is handled by auth_provider
    // This ensures listeners are setup before connection
  } catch (e) {
    developer.log('Error in socket initialization: $e', name: 'Main', error: e);
  }
}

/// Handle notification received in foreground
void _handleNotificationReceived(Map<String, dynamic> data) {
  developer.log('📬 Notification received in foreground: $data', name: 'Main');

  // Update unread count in notification provider
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      final container = ProviderScope.containerOf(navigatorKey.currentContext!);
      final notifier = container.read(notificationProvider.notifier);

      // Increment unread count immediately for instant feedback
      final currentCount = container.read(notificationProvider).unreadCount;
      notifier.updateUnreadCount(currentCount + 1);

      // Then fetch actual count from server in background
      notifier.getUnreadCount();

      developer.log('✅ Notification unread count updated', name: 'Main');
    } catch (e) {
      developer.log(
        '❌ Error updating notification count: $e',
        name: 'Main',
        error: e,
      );
    }
  });
}

/// Handle notification opened
void _handleNotificationOpened(Map<String, dynamic> data) {
  developer.log('📲 Notification opened with data: $data', name: 'Main');

  final type = data['type'] as String?;

  // Navigate based on notification type
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      developer.log(
        '⚠️ Navigator context is null, cannot navigate',
        name: 'Main',
      );
      return;
    }

    switch (type) {
      case 'chat_message':
      case 'message':
        _handleChatNotification(context, data);
        break;

      case 'booking':
      case 'new_booking':
      case 'booking_status':
        _handleBookingNotification(context, data);
        break;

      case 'review':
      case 'new_review':
        _handleReviewNotification(context, data);
        break;

      default:
        developer.log('⚠️ Unknown notification type: $type', name: 'Main');
        // If unknown type but we want to open app, just go to home
        _navigateToHome(context);
    }
  });
}

/// Helper to get the correct home route based on user role
String _getHomeRoute(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context);
    final authState = container.read(authProvider);
    final user = authState.user;

    if (user != null && user.role == 'photographer') {
      return '/photographer-dashboard';
    }
  } catch (e) {
    developer.log('Error getting user role: $e', name: 'Main');
  }
  return '/home'; // Default to client home
}

/// Helper to navigate with stack reset
void _navigateWithStackReset(
  BuildContext context,
  String targetRoute, {
  Object? arguments,
}) {
  final homeRoute = _getHomeRoute(context);

  // Reset stack to Home
  Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);

  // Immediately push the target route on top of Home
  Navigator.pushNamed(context, targetRoute, arguments: arguments);
}

/// Helper to just navigate to home (clearing stack)
void _navigateToHome(BuildContext context) {
  final homeRoute = _getHomeRoute(context);
  Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
}

/// Handle chat message notification
void _handleChatNotification(BuildContext context, Map<String, dynamic> data) {
  final conversationId = data['conversationId'] as String?;
  final senderId = data['senderId'] as String?;
  final senderName = data['senderName'] as String?;
  final senderAvatar = data['senderAvatar'] as String?;

  developer.log(
    '💬 Opening chat: conversationId=$conversationId, senderId=$senderId',
    name: 'Main',
  );

  if (conversationId != null && senderId != null) {
    _navigateWithStackReset(
      context,
      '/chat',
      arguments: {
        'conversationId': conversationId,
        'otherUserId': senderId,
        'otherUserName': senderName ?? 'مستخدم',
        'otherUserAvatar': senderAvatar,
      },
    );
  } else {
    developer.log('⚠️ Missing required chat data', name: 'Main');
    _navigateToHome(context);
  }
}

/// Handle booking notification
void _handleBookingNotification(
  BuildContext context,
  Map<String, dynamic> data,
) {
  final bookingId = data['bookingId'] as String?;

  developer.log('📅 Opening booking: bookingId=$bookingId', name: 'Main');

  if (bookingId != null) {
    _navigateWithStackReset(context, '/booking-details', arguments: bookingId);
  } else {
    // Navigate to bookings list if no specific booking ID
    _navigateWithStackReset(context, '/my-bookings');
  }
}

/// Handle review notification
void _handleReviewNotification(
  BuildContext context,
  Map<String, dynamic> data,
) {
  developer.log('⭐ Opening reviews', name: 'Main');

  // Navigate to profile/reviews page
  // Note: '/profile' might be user profile, check if we need photographer specific review page
  // If it's a photographer receiving a review, they probably want to see their reviews.
  // The original code went to '/profile'. Let's keep it but use the reset.
  // If it is a photographer, '/profile' might be the wrong place if it's the client profile page.
  // However, based on existing code, we will stick to the requested behavior of just fixing navigation.

  _navigateWithStackReset(context, '/profile');
}
