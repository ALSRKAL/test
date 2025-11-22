import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';
import '../services/sync_service.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';

// مزود خدمة الأوف لاين
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

// مزود حالة الاتصال
final connectivityProvider = StreamProvider<bool>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  return offlineService.connectivityStream;
});

// مزود خدمة المزامنة
final syncServiceProvider = Provider<SyncService>((ref) {
  final offlineService = ref.watch(offlineServiceProvider);
  // استخدام baseUrl من ApiEndpoints
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  return SyncService(offlineService, dio);
});

// مزود عدد العمليات المعلقة
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final operations = await offlineService.getPendingSyncOperations();
  return operations.length;
});

// مزود حالة المزامنة
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.idle);

  void setSyncing() => state = SyncStatus.syncing;
  void setSuccess() => state = SyncStatus.success;
  void setError() => state = SyncStatus.error;
  void setIdle() => state = SyncStatus.idle;
}

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}
