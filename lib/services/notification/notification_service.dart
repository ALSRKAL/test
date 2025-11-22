import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:developer' as developer;

/// Service for managing push notifications using OneSignal
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Function(Map<String, dynamic>)? _onNotificationOpened;

  /// Initialize OneSignal
  Future<void> initialize(
    String appId, {
    Function(Map<String, dynamic>)? onNotificationOpened,
  }) async {
    _onNotificationOpened = onNotificationOpened;

    // Initialize OneSignal
    OneSignal.initialize(appId);

    // Request permission for notifications
    await OneSignal.Notifications.requestPermission(true);

    // Set up notification handlers
    _setupHandlers();

    developer.log(
      'OneSignal initialized with App ID: $appId',
      name: 'NotificationService',
    );
  }

  Function(Map<String, dynamic>)? _onNotificationReceived;

  String? _currentConversationId;

  /// Set the current active conversation ID
  void setCurrentConversationId(String? id) {
    _currentConversationId = id;
    developer.log(
      'Current conversation ID set to: $_currentConversationId',
      name: 'NotificationService',
    );
  }

  /// Set up notification event handlers
  void _setupHandlers() {
    // Handle notification opened (when user taps on notification)
    OneSignal.Notifications.addClickListener((event) {
      developer.log(
        'Notification clicked: ${event.notification.additionalData}',
        name: 'NotificationService',
      );
      _handleNotificationOpened(event.notification.additionalData);
    });

    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      developer.log(
        'Notification received in foreground: ${event.notification.additionalData}',
        name: 'NotificationService',
      );

      final data = event.notification.additionalData;

      // Check if we are in the chat that sent this notification
      if (data != null && _currentConversationId != null) {
        // Check for conversationId or chatId in the payload
        final notificationConversationId =
            data['conversationId'] ?? data['chatId'];

        if (notificationConversationId != null &&
            notificationConversationId.toString() == _currentConversationId) {
          developer.log(
            'Suppressing notification for active conversation: $_currentConversationId',
            name: 'NotificationService',
          );
          // Prevent notification from showing
          event.preventDefault();
          return;
        }
      }

      // Notify listeners about new notification
      if (_onNotificationReceived != null && data != null) {
        _onNotificationReceived!(data);
      }

      // Allow notification to display even in foreground (if not prevented above)
      event.notification.display();
    });

    // Handle permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      developer.log(
        'Notification permission changed: $state',
        name: 'NotificationService',
      );
    });
  }

  /// Handle notification opened
  void _handleNotificationOpened(Map<String, dynamic>? data) {
    if (data == null) return;

    developer.log('Handling notification: $data', name: 'NotificationService');

    // Call custom handler if provided
    if (_onNotificationOpened != null) {
      _onNotificationOpened!(data);
    }
  }

  /// Set external user ID (after login)
  Future<void> setExternalUserId(String userId) async {
    try {
      developer.log(
        'Attempting to set OneSignal user ID: $userId',
        name: 'NotificationService',
      );
      await OneSignal.login(userId);
      developer.log(
        '✅ OneSignal user ID set successfully: $userId',
        name: 'NotificationService',
      );

      // Check permission status
      final permission = OneSignal.Notifications.permission;
      developer.log(
        'Current notification permission: $permission',
        name: 'NotificationService',
      );

      if (!permission) {
        developer.log(
          '⚠️ Notifications disabled, requesting permission...',
          name: 'NotificationService',
        );
        await promptForPushPermission();
      }
    } catch (e) {
      developer.log(
        '❌ Error setting OneSignal user ID: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Remove external user ID (after logout)
  Future<void> removeExternalUserId() async {
    try {
      await OneSignal.logout();
      developer.log('OneSignal user logged out', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error logging out OneSignal user: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Send a tag
  Future<void> sendTag(String key, String value) async {
    try {
      await OneSignal.User.addTagWithKey(key, value);
      developer.log(
        'OneSignal tag added: $key = $value',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error adding OneSignal tag: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Remove a tag
  Future<void> removeTag(String key) async {
    try {
      await OneSignal.User.removeTag(key);
      developer.log('OneSignal tag removed: $key', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'Error removing OneSignal tag: $e',
        name: 'NotificationService',
        error: e,
      );
    }
  }

  /// Get notification permission status
  Future<bool> getPermissionStatus() async {
    return OneSignal.Notifications.permission;
  }

  /// Prompt for push permission
  Future<bool> promptForPushPermission() async {
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      developer.log('Push permission: $granted', name: 'NotificationService');
      return granted;
    } catch (e) {
      developer.log(
        'Error requesting push permission: $e',
        name: 'NotificationService',
        error: e,
      );
      return false;
    }
  }

  /// Get OneSignal Player ID
  String? getPlayerId() {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      developer.log(
        'Error getting player ID: $e',
        name: 'NotificationService',
        error: e,
      );
      return null;
    }
  }

  /// Set notification opened handler
  void setNotificationOpenedHandler(Function(Map<String, dynamic>) handler) {
    _onNotificationOpened = handler;
  }

  /// Set notification received handler (for foreground notifications)
  void setNotificationReceivedHandler(Function(Map<String, dynamic>) handler) {
    _onNotificationReceived = handler;
  }
}
