import 'package:hive_flutter/hive_flutter.dart';

/// Manager for handling cache operations using Hive
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  /// Initialize Hive
  Future<void> initialize() async {
    await Hive.initFlutter();
  }

  /// Open a box
  Future<Box> openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return await Hive.openBox(boxName);
  }

  /// Save data to cache
  Future<void> save(String boxName, String key, dynamic value) async {
    final box = await openBox(boxName);
    await box.put(key, {
      'data': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get data from cache
  Future<dynamic> get(String boxName, String key) async {
    final box = await openBox(boxName);
    final cached = box.get(key);
    if (cached == null) return null;
    return cached['data'];
  }

  /// Get data with expiry check
  Future<dynamic> getWithExpiry(
    String boxName,
    String key,
    int expiryHours,
  ) async {
    final box = await openBox(boxName);
    final cached = box.get(key);
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final hours = diff / (1000 * 60 * 60);

    if (hours > expiryHours) {
      await box.delete(key);
      return null;
    }

    return cached['data'];
  }

  /// Delete data from cache
  Future<void> delete(String boxName, String key) async {
    final box = await openBox(boxName);
    await box.delete(key);
  }

  /// Clear all data in a box
  Future<void> clearBox(String boxName) async {
    final box = await openBox(boxName);
    await box.clear();
  }

  /// Clear all boxes
  Future<void> clearAll() async {
    await Hive.deleteFromDisk();
  }

  /// Check if key exists
  Future<bool> exists(String boxName, String key) async {
    final box = await openBox(boxName);
    return box.containsKey(key);
  }

  /// Get all keys in a box
  Future<List<String>> getAllKeys(String boxName) async {
    final box = await openBox(boxName);
    return box.keys.cast<String>().toList();
  }

  /// Get box size
  Future<int> getBoxSize(String boxName) async {
    final box = await openBox(boxName);
    return box.length;
  }

  /// Close a box
  Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  /// Close all boxes
  Future<void> closeAll() async {
    await Hive.close();
  }
}
