import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import '../../core/constants/api_endpoints.dart';

/// Service for managing Socket.IO connections
/// This is a singleton to ensure only one Socket.IO connection exists
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    developer.log(
      'SocketService instance requested (singleton)',
      name: 'SocketService',
    );
    return _instance;
  }
  SocketService._internal() {
    developer.log('SocketService singleton created', name: 'SocketService');
  }

  io.Socket? _socket;
  final _storage = const FlutterSecureStorage();
  String? _currentUserId;

  bool get isConnected => _socket?.connected ?? false;

  // Connection event listeners
  final List<Function()> _connectListeners = [];
  final List<Function()> _disconnectListeners = [];
  final List<Function()> _reconnectListeners = [];

  /// Add listener for connect event
  void onConnect(Function() callback) {
    _connectListeners.add(callback);
  }

  /// Add listener for disconnect event
  void onDisconnect(Function() callback) {
    _disconnectListeners.add(callback);
  }

  /// Add listener for reconnect event
  void onReconnect(Function() callback) {
    _reconnectListeners.add(callback);
  }

  /// Connect to Socket.IO server
  Future<void> connect({String? userId}) async {
    developer.log('🔌 connect() called', name: 'SocketService');
    developer.log(
      '   Current socket connected: ${_socket?.connected}',
      name: 'SocketService',
    );
    developer.log('   User ID: $userId', name: 'SocketService');

    if (_socket?.connected == true) {
      developer.log('⚠️ Socket already connected', name: 'SocketService');

      // Always update current user ID
      _currentUserId = userId;

      // If we have a user ID, make sure to emit user_connected again
      // This ensures we are in the correct room even if the server restarted
      if (userId != null) {
        developer.log(
          '🔄 Re-emitting user_connected for user: $userId',
          name: 'SocketService',
        );
        _socket?.emit('user_connected', userId);
      }

      return;
    }

    _currentUserId = userId;
    developer.log(
      '🔌 Connecting to Socket.IO server...',
      name: 'SocketService',
    );
    developer.log('   User ID: $userId', name: 'SocketService');

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      developer.log('❌ No access token found', name: 'SocketService');
      return;
    }

    developer.log(
      '   Token exists: ${token.substring(0, 20)}...',
      name: 'SocketService',
    );
    developer.log(
      '   Socket URL: ${ApiEndpoints.socketUrl}',
      name: 'SocketService',
    );

    _socket = io.io(
      ApiEndpoints.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    // IMPORTANT: Setup listeners BEFORE connecting
    developer.log(
      '🔧 Setting up Socket event listeners...',
      name: 'SocketService',
    );

    // Listen for test response
    _socket?.on('test_response', (data) {
      developer.log(
        '🧪 Test response received from server!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
    });

    // Listen for connection confirmation
    _socket?.on('connection_confirmed', (data) {
      developer.log('✅ Connection confirmed by server!', name: 'SocketService');
      developer.log('   Data: $data', name: 'SocketService');
      developer.log(
        '   You are now in room: user_$_currentUserId',
        name: 'SocketService',
      );
    });

    _socket?.onConnect((_) {
      developer.log('✅ Socket connected!', name: 'SocketService');
      developer.log('   Socket ID: ${_socket?.id}', name: 'SocketService');
      developer.log(
        '   Connected: ${_socket?.connected}',
        name: 'SocketService',
      );

      // Notify listeners
      for (final listener in _connectListeners) {
        try {
          listener();
        } catch (e) {
          developer.log('Error in connect listener: $e', name: 'SocketService');
        }
      }

      if (_currentUserId != null) {
        developer.log(
          '📤 Emitting user_connected event for user: $_currentUserId',
          name: 'SocketService',
        );
        _socket?.emit('user_connected', _currentUserId);

        // Test: emit a test event to verify connection
        developer.log('🧪 Testing Socket connection...', name: 'SocketService');
        _socket?.emit('test_connection', {
          'userId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        developer.log(
          '⚠️ No userId available for user_connected event',
          name: 'SocketService',
        );
      }
    });

    // Handle reconnection specifically
    _socket?.onReconnect((_) {
      developer.log('🔄 Socket reconnected!', name: 'SocketService');

      // Notify listeners
      for (final listener in _reconnectListeners) {
        try {
          listener();
        } catch (e) {
          developer.log(
            'Error in reconnect listener: $e',
            name: 'SocketService',
          );
        }
      }

      if (_currentUserId != null) {
        developer.log(
          '📤 Re-emitting user_connected after reconnection',
          name: 'SocketService',
        );
        _socket?.emit('user_connected', _currentUserId);
      }
    });

    // Now connect
    developer.log('🔌 Initiating Socket connection...', name: 'SocketService');
    _socket?.connect();

    developer.log('🔌 Socket connect() method called', name: 'SocketService');
    developer.log('   Waiting for connection...', name: 'SocketService');

    _socket?.onDisconnect((_) {
      developer.log('Socket disconnected', name: 'SocketService');

      // Notify listeners
      for (final listener in _disconnectListeners) {
        try {
          listener();
        } catch (e) {
          developer.log(
            'Error in disconnect listener: $e',
            name: 'SocketService',
          );
        }
      }
    });

    _socket?.onError((error) {
      developer.log(
        'Socket error: $error',
        name: 'SocketService',
        error: error,
      );
    });
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
  }

  /// Join a conversation room
  void joinRoom(String conversationId) {
    _socket?.emit('join_conversation', conversationId);
    developer.log(
      'Joined conversation: $conversationId',
      name: 'SocketService',
    );
  }

  /// Leave a conversation room
  void leaveRoom(String conversationId) {
    _socket?.emit('leave_conversation', conversationId);
    developer.log('Left conversation: $conversationId', name: 'SocketService');
  }

  /// Send a message via socket
  void sendMessage(Map<String, dynamic> message) {
    _socket?.emit('send_message', message);
  }

  /// Listen for new messages
  void onNewMessage(Function(dynamic) callback) {
    _socket?.on('new_message', callback);
  }

  /// Send typing indicator
  void sendTyping(String conversationId, String userId, String userName) {
    _socket?.emit('typing_start', {
      'conversationId': conversationId,
      'userId': userId,
      'userName': userName,
    });
  }

  /// Stop typing indicator
  void stopTyping(String conversationId, String userId) {
    _socket?.emit('typing_stop', {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  /// Listen for typing indicator
  void onTyping(Function(dynamic) callback) {
    _socket?.on('user_typing', callback);
  }

  /// Listen for stop typing
  void onStopTyping(Function(dynamic) callback) {
    _socket?.on('user_stop_typing', callback);
  }

  /// Mark messages as read
  void markAsRead(String conversationId, String userId) {
    _socket?.emit('mark_as_read', {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  /// Listen for messages read
  void onMessagesRead(Function(dynamic) callback) {
    _socket?.on('messages_read', callback);
  }

  /// Delete message
  void deleteMessage(String messageId, String userId) {
    _socket?.emit('delete_message', {'messageId': messageId, 'userId': userId});
  }

  /// Listen for message deleted
  void onMessageDeleted(Function(dynamic) callback) {
    _socket?.on('message_deleted', callback);
  }

  /// Listen for online status
  void onUserOnline(Function(dynamic) callback) {
    _socket?.on('user_online', callback);
  }

  /// Listen for offline status
  void onUserOffline(Function(dynamic) callback) {
    _socket?.on('user_offline', callback);
  }

  /// Check online status
  void checkOnlineStatus(String userId) {
    _socket?.emit('check_online_status', userId);
  }

  /// Listen for online status response
  void onOnlineStatusResponse(Function(dynamic) callback) {
    _socket?.on('online_status_response', callback);
  }

  /// Remove all listeners
  void removeAllListeners() {
    _socket?.clearListeners();
  }

  /// Remove specific listener
  void removeListener(String event) {
    _socket?.off(event);
  }

  /// Listen for user banned event
  void onUserBanned(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: user_banned',
      name: 'SocketService',
    );
    _socket?.on('user_banned', (data) {
      developer.log(
        '🚫 [SocketService] user_banned event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }

  /// Listen for user unblocked event
  void onUserUnblocked(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: user_unblocked',
      name: 'SocketService',
    );
    _socket?.on('user_unblocked', (data) {
      developer.log(
        '✅ [SocketService] user_unblocked event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }

  // ============ Booking Events ============

  /// Listen for new booking notifications (for photographers)
  void onNewBooking(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: new_booking',
      name: 'SocketService',
    );
    _socket?.on('new_booking', (data) {
      developer.log(
        '📅 [SocketService] new_booking event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }

  /// Listen for booking status updates (for clients)
  void onBookingStatusUpdated(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: booking_status_updated',
      name: 'SocketService',
    );
    _socket?.on('booking_status_updated', (data) {
      developer.log(
        '📝 [SocketService] booking_status_updated event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }

  /// Join bookings room for receiving booking notifications
  void joinBookingsRoom(String userId) {
    _socket?.emit('join_bookings_room', userId);
    developer.log(
      'Joined bookings room for user: $userId',
      name: 'SocketService',
    );
  }

  /// Leave bookings room
  void leaveBookingsRoom(String userId) {
    _socket?.emit('leave_bookings_room', userId);
    developer.log(
      'Left bookings room for user: $userId',
      name: 'SocketService',
    );
  }

  // ============ Notification Events ============

  /// Listen for new notifications
  void onNewNotification(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: new_notification',
      name: 'SocketService',
    );
    _socket?.on('new_notification', (data) {
      developer.log(
        '📬 [SocketService] new_notification event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }

  /// Listen for notification count updates
  void onNotificationCountUpdate(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: notification_count_update',
      name: 'SocketService',
    );
    _socket?.on('notification_count_update', (data) {
      developer.log(
        '🔔 [SocketService] notification_count_update event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }

  /// Join notifications room
  void joinNotificationsRoom(String userId) {
    _socket?.emit('join_notifications_room', userId);
    developer.log(
      'Joined notifications room for user: $userId',
      name: 'SocketService',
    );
  }

  /// Leave notifications room
  void leaveNotificationsRoom(String userId) {
    _socket?.emit('leave_notifications_room', userId);
    developer.log(
      'Left notifications room for user: $userId',
      name: 'SocketService',
    );
  }

  /// Listen for notification updated (marked as read)
  void onNotificationUpdated(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: notification_updated',
      name: 'SocketService',
    );
    _socket?.on('notification_updated', (data) {
      developer.log(
        '🔔 [SocketService] notification_updated event received!',
        name: 'SocketService',
      );
      callback(data);
    });
  }

  /// Listen for all notifications marked as read
  void onNotificationsMarkedAllRead(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: notifications_marked_all_read',
      name: 'SocketService',
    );
    _socket?.on('notifications_marked_all_read', (data) {
      developer.log(
        '🔔 [SocketService] notifications_marked_all_read event received!',
        name: 'SocketService',
      );
      callback(data);
    });
  }

  /// Listen for notification deletion
  void onNotificationDeleted(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: notification_deleted',
      name: 'SocketService',
    );
    _socket?.on('notification_deleted', (data) {
      developer.log(
        '🗑️ [SocketService] notification_deleted event received!',
        name: 'SocketService',
      );
      callback(data);
    });
  }

  // ============ Unread Count Events ============

  /// Listen for unread messages count update
  void onUnreadMessagesUpdate(Function(dynamic) callback) {
    _socket?.on('unread_messages_update', callback);
  }

  /// Listen for pending bookings count update
  void onPendingBookingsUpdate(Function(dynamic) callback) {
    developer.log(
      '📝 Registering listener for: pending_bookings_update',
      name: 'SocketService',
    );
    _socket?.on('pending_bookings_update', (data) {
      developer.log(
        '⏳ [SocketService] pending_bookings_update event received!',
        name: 'SocketService',
      );
      developer.log('   Data: $data', name: 'SocketService');
      callback(data);
    });
  }
}
