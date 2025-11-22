import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/data/mock_data.dart';

// Provider للمستخدم الحالي
final currentUserProvider = StateNotifierProvider<UserNotifier, Map<String, dynamic>?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<Map<String, dynamic>?> {
  UserNotifier() : super(MockData.currentUser);

  // تحديث بيانات المستخدم
  void updateUser(Map<String, dynamic> updates) {
    if (state != null) {
      state = {...state!, ...updates};
    }
  }

  // تسجيل الخروج
  void logout() {
    state = null;
  }

  // تسجيل الدخول
  void login(Map<String, dynamic> user) {
    state = user;
  }
}

// Provider للتحقق من تسجيل الدخول
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
