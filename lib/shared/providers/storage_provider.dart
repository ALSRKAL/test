import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/local_storage/hive_service.dart';
import '../../services/local_storage/secure_storage_service.dart';

/// Provider for Hive service
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Provider for Secure Storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for checking if user is logged in
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return await secureStorage.isLoggedIn();
});
