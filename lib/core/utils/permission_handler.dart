import 'package:permission_handler/permission_handler.dart';

/// Handler for managing app permissions
class PermissionHandler {
  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request photos permission (iOS)
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Check if photos permission is granted
  static Future<bool> isPhotosPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Request multiple permissions
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }
}
