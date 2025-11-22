import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/data/mock_data.dart';

// Provider للمحادثات
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Map<String, dynamic>>>((ref) {
  return ConversationsNotifier();
});

class ConversationsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ConversationsNotifier() : super(List<Map<String, dynamic>>.from(MockData.conversations));

  // تحديث آخر رسالة
  void updateLastMessage(String conversationId, String message, String time) {
    state = state.map((conv) {
      if (conv['id'] == conversationId) {
        return {
          ...conv,
          'lastMessage': message,
          'lastMessageTime': time,
          'unreadCount': (conv['unreadCount'] as int) + 1,
        };
      }
      return conv;
    }).toList();
  }

  // تصفير عدد الرسائل غير المقروءة
  void markAsRead(String conversationId) {
    state = state.map((conv) {
      if (conv['id'] == conversationId) {
        return {...conv, 'unreadCount': 0};
      }
      return conv;
    }).toList();
  }

  // الحصول على إجمالي الرسائل غير المقروءة
  int get totalUnreadCount {
    return state.fold(0, (sum, conv) => sum + (conv['unreadCount'] as int));
  }
}

// Provider للرسائل
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Map<String, dynamic>>, String>(
  (ref, conversationId) {
    return MessagesNotifier(conversationId);
  },
);

class MessagesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final String conversationId;

  MessagesNotifier(this.conversationId)
      : super(List<Map<String, dynamic>>.from(MockData.messages[conversationId] ?? []));

  // إرسال رسالة
  void sendMessage(String text, String senderId) {
    final newMessage = {
      'id': 'm${state.length + 1}',
      'senderId': senderId,
      'text': text,
      'timestamp': DateTime.now().toString().substring(0, 16),
      'isRead': false,
    };
    state = [...state, newMessage];
  }

  // تحديد الرسائل كمقروءة
  void markAllAsRead() {
    state = state.map((msg) => {...msg, 'isRead': true}).toList();
  }
}

// Provider لحالة الكتابة
final typingStatusProvider = StateNotifierProvider.family<TypingStatusNotifier, bool, String>(
  (ref, conversationId) {
    return TypingStatusNotifier();
  },
);

class TypingStatusNotifier extends StateNotifier<bool> {
  TypingStatusNotifier() : super(false);

  void setTyping(bool isTyping) {
    state = isTyping;
  }
}
