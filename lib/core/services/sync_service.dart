import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'offline_service.dart';

/// خدمة المزامنة التلقائية
class SyncService {
  final OfflineService _offlineService;
  final Dio _dio;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncService(this._offlineService, this._dio);

  // بدء المزامنة التلقائية
  void startAutoSync() {
    // المزامنة كل 5 دقائق
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPendingOperations();
    });

    // المزامنة عند استعادة الاتصال
    _connectivitySubscription = _offlineService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        syncPendingOperations();
      }
    });
  }

  // إيقاف المزامنة التلقائية
  void stopAutoSync() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // مزامنة العمليات المعلقة (لا تعيق التطبيق)
  Future<void> syncPendingOperations() async {
    try {
      final isOnline = await _offlineService.isOnline();
      if (!isOnline) return;

      final operations = await _offlineService.getPendingSyncOperations();

      for (final operation in operations) {
        try {
          await _executeSyncOperation(operation);
          await _offlineService.removeSyncOperation(operation['id'] as int);
        } catch (e) {
          // تسجيل الخطأ وإعادة المحاولة لاحقاً
          await _offlineService.incrementRetryCount(
            operation['id'] as int,
            e.toString(),
          );
        }
      }
    } catch (e) {
      // تجاهل أخطاء المزامنة لعدم إعاقة التطبيق
    }
  }

  // تنفيذ عملية مزامنة
  Future<void> _executeSyncOperation(Map<String, dynamic> operation) async {
    final method = operation['method'] as String;
    final endpoint = operation['endpoint'] as String;
    final data = jsonDecode(operation['data'] as String);

    Response response;

    switch (method.toUpperCase()) {
      case 'POST':
        response = await _dio.post(endpoint, data: data);
        break;
      case 'PUT':
        response = await _dio.put(endpoint, data: data);
        break;
      case 'DELETE':
        response = await _dio.delete(endpoint, data: data);
        break;
      case 'PATCH':
        response = await _dio.patch(endpoint, data: data);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      throw Exception('Sync failed with status: ${response.statusCode}');
    }
  }

  // مزامنة يدوية
  Future<SyncResult> manualSync() async {
    try {
      final isOnline = await _offlineService.isOnline();
      if (!isOnline) {
        return SyncResult(
          success: false,
          message: 'لا يوجد اتصال بالإنترنت',
          syncedCount: 0,
        );
      }

      final operations = await _offlineService.getPendingSyncOperations();
      int syncedCount = 0;
      int failedCount = 0;

      for (final operation in operations) {
        try {
          await _executeSyncOperation(operation);
          await _offlineService.removeSyncOperation(operation['id'] as int);
          syncedCount++;
        } catch (e) {
          failedCount++;
          await _offlineService.incrementRetryCount(
            operation['id'] as int,
            e.toString(),
          );
        }
      }

      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'تمت المزامنة بنجاح'
            : 'تمت مزامنة $syncedCount عملية، فشل $failedCount',
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'فشلت المزامنة: ${e.toString()}',
        syncedCount: 0,
      );
    }
  }

  void dispose() {
    stopAutoSync();
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    this.failedCount = 0,
  });
}
