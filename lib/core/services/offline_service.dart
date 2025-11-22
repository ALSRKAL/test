import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// خدمة إدارة الوضع الأوف لاين
class OfflineService {
  final AppDatabase _database = AppDatabase.instance;
  final Connectivity _connectivity = Connectivity();

  // التحقق من الاتصال بالإنترنت
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // الاستماع لتغييرات الاتصال
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  // إضافة عملية للمزامنة
  Future<void> addToSyncQueue({
    required String operation,
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
  }) async {
    final db = await _database.database;
    await db.insert('sync_queue', {
      'operation': operation,
      'endpoint': endpoint,
      'method': method,
      'data': jsonEncode(data),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });
  }

  // الحصول على العمليات المعلقة
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await _database.database;
    return await db.query('sync_queue', orderBy: 'createdAt ASC');
  }

  // حذف عملية من قائمة المزامنة
  Future<void> removeSyncOperation(int id) async {
    final db = await _database.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // تحديث عدد المحاولات
  Future<void> incrementRetryCount(int id, String error) async {
    final db = await _database.database;
    await db.update(
      'sync_queue',
      {'retryCount': 1, 'lastError': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حفظ مصور محلياً
  Future<void> savePhotographerLocally(
    Map<String, dynamic> photographer,
  ) async {
    final db = await _database.database;
    await db.insert('photographers', {
      'id': photographer['_id'] ?? photographer['id'],
      'name': photographer['name'],
      'email': photographer['email'],
      'phone': photographer['phone'],
      'bio': photographer['bio'],
      'profileImage': photographer['profileImage'],
      'coverImage': photographer['coverImage'],
      'rating': photographer['rating'] ?? 0.0,
      'reviewCount': photographer['reviewCount'] ?? 0,
      'city': photographer['city'],
      'specialties': jsonEncode(photographer['specialties'] ?? []),
      'priceRange': photographer['priceRange'],
      'isFavorite': photographer['isFavorite'] == true ? 1 : 0,
      'lastSync': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(photographer),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // الحصول على المصورين المحفوظين
  Future<List<Map<String, dynamic>>> getLocalPhotographers() async {
    final db = await _database.database;
    final results = await db.query('photographers');
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      data['isFavorite'] = row['isFavorite'] == 1;
      return data;
    }).toList();
  }

  // حفظ حجز محلياً
  Future<void> saveBookingLocally(
    Map<String, dynamic> booking, {
    bool isPending = false,
  }) async {
    final db = await _database.database;
    await db.insert('bookings', {
      'id':
          booking['_id'] ??
          booking['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': booking['userId'],
      'photographerId': booking['photographerId'],
      'packageId': booking['packageId'],
      'date': booking['date'],
      'time': booking['time'],
      'status': booking['status'] ?? 'pending',
      'location': booking['location'],
      'notes': booking['notes'],
      'totalPrice': booking['totalPrice'],
      'isPending': isPending ? 1 : 0,
      'lastSync': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(booking),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // الحصول على الحجوزات المحفوظة
  Future<List<Map<String, dynamic>>> getLocalBookings(String userId) async {
    final db = await _database.database;
    final results = await db.query(
      'bookings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      data['isPending'] = row['isPending'] == 1;
      return data;
    }).toList();
  }

  // حفظ تقييم محلياً
  Future<void> saveReviewLocally(
    Map<String, dynamic> review, {
    bool isPending = false,
  }) async {
    final db = await _database.database;
    await db.insert('reviews', {
      'id':
          review['_id'] ??
          review['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'photographerId': review['photographerId'],
      'userId': review['userId'],
      'userName': review['userName'],
      'userAvatar': review['userAvatar'],
      'rating': review['rating'],
      'comment': review['comment'],
      'images': jsonEncode(review['images'] ?? []),
      'createdAt': review['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      'isPending': isPending ? 1 : 0,
      'lastSync': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(review),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // الحصول على التقييمات المحفوظة
  Future<List<Map<String, dynamic>>> getLocalReviews(
    String photographerId,
  ) async {
    final db = await _database.database;
    final results = await db.query(
      'reviews',
      where: 'photographerId = ?',
      whereArgs: [photographerId],
      orderBy: 'createdAt DESC',
    );
    return results.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      data['isPending'] = row['isPending'] == 1;
      return data;
    }).toList();
  }

  // حفظ إشعار محلياً
  Future<void> saveNotificationLocally(
    Map<String, dynamic> notification,
  ) async {
    final db = await _database.database;
    await db.insert('notifications', {
      'id': notification['_id'] ?? notification['id'],
      'userId': notification['userId'],
      'title': notification['title'],
      'body': notification['body'],
      'type': notification['type'],
      'data': jsonEncode(notification['data'] ?? {}),
      'isRead': notification['isRead'] == true ? 1 : 0,
      'createdAt':
          notification['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      'lastSync': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // الحصول على الإشعارات المحفوظة
  Future<List<Map<String, dynamic>>> getLocalNotifications(
    String userId,
  ) async {
    final db = await _database.database;
    final results = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return results.map((row) {
      return {
        'id': row['id'],
        'userId': row['userId'],
        'title': row['title'],
        'body': row['body'],
        'type': row['type'],
        'data': jsonDecode(row['data'] as String),
        'isRead': row['isRead'] == 1,
        'createdAt': row['createdAt'],
      };
    }).toList();
  }

  // حذف إشعار محلياً
  Future<void> deleteNotificationLocally(String notificationId) async {
    final db = await _database.database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // حذف جميع الإشعارات محلياً
  Future<void> deleteAllNotificationsLocally() async {
    final db = await _database.database;
    await db.delete('notifications');
  }

  // تحديث حالة المفضلة
  Future<void> updateFavoriteStatus(
    String photographerId,
    bool isFavorite,
  ) async {
    final db = await _database.database;
    await db.update(
      'photographers',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [photographerId],
    );
  }

  // الحصول على المصورين المفضلين
  Future<List<Map<String, dynamic>>> getFavoritePhotographers() async {
    final db = await _database.database;
    final results = await db.query(
      'photographers',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return results.map((row) {
      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    }).toList();
  }
}
