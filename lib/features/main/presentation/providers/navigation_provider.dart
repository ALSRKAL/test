import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider للتحكم في التنقل بين الصفحات الرئيسية
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  /// التنقل إلى صفحة معينة
  void navigateTo(int index) {
    if (index >= 0 && index <= 3) {
      state = index;
    }
  }

  /// التنقل إلى الصفحة الرئيسية
  void goToHome() => state = 0;

  /// التنقل إلى صفحة الحجوزات
  void goToBookings() => state = 1;

  /// التنقل إلى صفحة المحادثات
  void goToChats() => state = 2;

  /// التنقل إلى صفحة الملف الشخصي
  void goToProfile() => state = 3;
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});
