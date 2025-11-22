import 'package:hive_flutter/hive_flutter.dart';
import '../database/app_database.dart';
import '../services/settings_storage.dart';

/// تهيئة نظام الأوف لاين
class OfflineInit {
  static Future<void> initialize() async {
    // تهيئة Hive
    await Hive.initFlutter();
    
    // تهيئة قاعدة البيانات
    await AppDatabase.instance.database;
    
    // تهيئة تخزين الإعدادات
    await SettingsStorage.init();
  }
}
