import 'package:hive_flutter/hive_flutter.dart';

/// خدمة تخزين الإعدادات محلياً باستخدام Hive
class SettingsStorage {
  static const String _boxName = 'settings';
  static Box? _box;

  // تهيئة Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Box get _storage {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SettingsStorage not initialized. Call init() first.');
    }
    return _box!;
  }

  // حفظ إعداد
  static Future<void> set(String key, dynamic value) async {
    await _storage.put(key, value);
  }

  // الحصول على إعداد
  static T? get<T>(String key, {T? defaultValue}) {
    return _storage.get(key, defaultValue: defaultValue) as T?;
  }

  // حذف إعداد
  static Future<void> remove(String key) async {
    await _storage.delete(key);
  }

  // مسح كل الإعدادات
  static Future<void> clear() async {
    await _storage.clear();
  }

  // التحقق من وجود إعداد
  static bool contains(String key) {
    return _storage.containsKey(key);
  }

  // الإعدادات الشائعة
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyAutoSync = 'auto_sync';
  static const String keySyncInterval = 'sync_interval';
  static const String keyImageQuality = 'image_quality';
  static const String keyOfflineMode = 'offline_mode';

  // حفظ وضع الثيم
  static Future<void> setThemeMode(String mode) => set(keyThemeMode, mode);
  static String getThemeMode() => get(keyThemeMode, defaultValue: 'system') ?? 'system';

  // حفظ اللغة
  static Future<void> setLanguage(String lang) => set(keyLanguage, lang);
  static String getLanguage() => get(keyLanguage, defaultValue: 'ar') ?? 'ar';

  // حفظ حالة الإشعارات
  static Future<void> setNotificationsEnabled(bool enabled) => 
      set(keyNotificationsEnabled, enabled);
  static bool getNotificationsEnabled() => 
      get(keyNotificationsEnabled, defaultValue: true) ?? true;

  // حفظ حالة المزامنة التلقائية
  static Future<void> setAutoSync(bool enabled) => set(keyAutoSync, enabled);
  static bool getAutoSync() => get(keyAutoSync, defaultValue: true) ?? true;

  // حفظ فترة المزامنة (بالدقائق)
  static Future<void> setSyncInterval(int minutes) => set(keySyncInterval, minutes);
  static int getSyncInterval() => get(keySyncInterval, defaultValue: 5) ?? 5;

  // حفظ جودة الصور
  static Future<void> setImageQuality(String quality) => set(keyImageQuality, quality);
  static String getImageQuality() => get(keyImageQuality, defaultValue: 'high') ?? 'high';

  // حفظ وضع الأوف لاين
  static Future<void> setOfflineMode(bool enabled) => set(keyOfflineMode, enabled);
  static bool getOfflineMode() => get(keyOfflineMode, defaultValue: false) ?? false;
}
