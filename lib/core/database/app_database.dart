import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// قاعدة البيانات المحلية للتطبيق
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hajzy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // جدول المصورين
    await db.execute('''
      CREATE TABLE photographers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        bio TEXT,
        profileImage TEXT,
        coverImage TEXT,
        rating REAL DEFAULT 0,
        reviewCount INTEGER DEFAULT 0,
        city TEXT,
        specialties TEXT,
        priceRange TEXT,
        isFavorite INTEGER DEFAULT 0,
        lastSync INTEGER,
        data TEXT
      )
    ''');

    // جدول الحجوزات
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        photographerId TEXT NOT NULL,
        packageId TEXT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        status TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        totalPrice REAL,
        isPending INTEGER DEFAULT 0,
        lastSync INTEGER,
        data TEXT,
        FOREIGN KEY (photographerId) REFERENCES photographers (id)
      )
    ''');

    // جدول التقييمات
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        photographerId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT,
        userAvatar TEXT,
        rating REAL NOT NULL,
        comment TEXT,
        images TEXT,
        createdAt INTEGER,
        isPending INTEGER DEFAULT 0,
        lastSync INTEGER,
        data TEXT,
        FOREIGN KEY (photographerId) REFERENCES photographers (id)
      )
    ''');

    // جدول الإشعارات
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT,
        data TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt INTEGER,
        lastSync INTEGER
      )
    ''');

    // جدول العمليات المعلقة (Sync Queue)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0,
        lastError TEXT
      )
    ''');

    // جدول الصور المحفوظة
    await db.execute('''
      CREATE TABLE cached_images (
        url TEXT PRIMARY KEY,
        localPath TEXT NOT NULL,
        cachedAt INTEGER NOT NULL,
        expiresAt INTEGER
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // إضافة migrations هنا عند الحاجة
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('photographers');
    await db.delete('bookings');
    await db.delete('reviews');
    await db.delete('notifications');
    await db.delete('sync_queue');
    await db.delete('cached_images');
  }
}
