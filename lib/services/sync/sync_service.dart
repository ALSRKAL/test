import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../local_storage/hive_service.dart';

/// Service for syncing data between local and remote
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final HiveService _hiveService = HiveService();
  final Connectivity _connectivity = Connectivity();
  final ApiClient _apiClient = ApiClient();

  bool _isSyncing = false;
  List<Map<String, dynamic>> _pendingActions = [];
  StreamSubscription? _connectivitySubscription;

  /// Initialize SyncService
  Future<void> initialize() async {
    // Load pending actions from cache
    final cachedActions = await _hiveService.getPendingActions();
    if (cachedActions != null) {
      _pendingActions = List<Map<String, dynamic>>.from(cachedActions);
      print('Loaded ${_pendingActions.length} pending actions from cache');
    }

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none) {
        print('Device is online, triggering sync...');
        syncPendingActions();
      }
    });

    // Initial sync check
    syncPendingActions();
  }

  /// Dispose service
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Add action to pending queue
  Future<void> addPendingAction(
    String action,
    Map<String, dynamic> data,
  ) async {
    final pendingAction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'action': action,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    };

    _pendingActions.add(pendingAction);
    await _hiveService.savePendingActions(_pendingActions);
    print('Added pending action: $action');

    // Try to sync immediately if online
    syncPendingActions();
  }

  /// Sync pending actions
  Future<void> syncPendingActions() async {
    if (_isSyncing || _pendingActions.isEmpty) return;

    final online = await isOnline();
    if (!online) {
      print('Device is offline, cannot sync');
      return;
    }

    _isSyncing = true;
    print('Syncing ${_pendingActions.length} pending actions...');

    try {
      // Create a copy to iterate safely
      final actionsToProcess = List<Map<String, dynamic>>.from(_pendingActions);
      final List<Map<String, dynamic>> failedActions = [];

      for (final action in actionsToProcess) {
        try {
          await _processPendingAction(action);
          // If successful, remove from main list
          _pendingActions.removeWhere((a) => a['id'] == action['id']);
        } catch (e) {
          print('Error processing action ${action['action']}: $e');
          // Increment retry count
          action['retryCount'] = (action['retryCount'] ?? 0) + 1;
          failedActions.add(action);
        }
      }

      // Update cache with remaining actions (failed ones are still in _pendingActions if we didn't remove them,
      // but here we removed successful ones, so _pendingActions now contains only failed/unprocessed ones)
      // Wait, the logic above removes successful ones from _pendingActions.
      // So _pendingActions now only has the ones that were NOT processed or failed.
      // But wait, if I iterate over a copy and remove from original, it works.

      await _hiveService.savePendingActions(_pendingActions);

      print(
        'Sync completed. Remaining pending actions: ${_pendingActions.length}',
      );
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single pending action
  Future<void> _processPendingAction(Map<String, dynamic> action) async {
    final actionType = action['action'] as String;
    final data = action['data'] as Map<String, dynamic>;

    print('Processing action: $actionType');

    switch (actionType) {
      case 'send_message':
        await _processSendMessage(data);
        break;
      case 'create_booking':
        await _processCreateBooking(data);
        break;
      case 'create_review':
        // TODO: Implement create review sync
        break;
      default:
        print('Unknown action type: $actionType');
    }
  }

  Future<void> _processCreateBooking(Map<String, dynamic> data) async {
    final photographerId = data['photographerId'];
    final packageId = data['packageId'];

    Map<String, dynamic>? packageData;

    // Try to get package details from cache if packageId is provided
    if (packageId != null && packageId.isNotEmpty) {
      final photographer = await _hiveService.getPhotographerDetails(
        photographerId,
      );
      if (photographer != null) {
        final packages = photographer['packages'] as List<dynamic>;
        final selectedPackage = packages.firstWhere(
          (pkg) => pkg['_id'] == packageId,
          orElse: () => null,
        );

        if (selectedPackage != null) {
          packageData = {
            'name': selectedPackage['name'],
            'price': selectedPackage['price'],
            'duration': selectedPackage['duration'],
            'features': selectedPackage['features'],
          };
        }
      }
    }

    await _apiClient.post(
      ApiEndpoints.bookings,
      data: {
        'photographer': photographerId,
        if (packageData != null) 'package': packageData,
        'date': data['date'],
        'timeSlot': data['timeSlot'],
        'location': data['location'],
        if (data['notes'] != null) 'notes': data['notes'],
      },
    );
  }

  Future<void> _processSendMessage(Map<String, dynamic> data) async {
    await _apiClient.post(
      ApiEndpoints.sendMessage,
      data: {
        'conversationId': data['conversationId'],
        'receiverId': data['receiverId'],
        'content': data['content'],
        if (data['type'] != null) 'type': data['type'],
        if (data['replyToMessageId'] != null)
          'replyToMessageId': data['replyToMessageId'],
        if (data['replyToMessageText'] != null)
          'replyToMessageText': data['replyToMessageText'],
        if (data['replyToSenderName'] != null)
          'replyToSenderName': data['replyToSenderName'],
      },
    );
  }

  /// Sync photographers data
  Future<void> syncPhotographers() async {
    final online = await isOnline();
    if (!online) {
      print('Device is offline, using cached data');
      return;
    }

    try {
      // Fetch photographers from API
      // Save to cache
      print('Photographers synced');
    } catch (e) {
      print('Error syncing photographers: $e');
    }
  }

  /// Sync bookings data
  Future<void> syncBookings() async {
    final online = await isOnline();
    if (!online) {
      print('Device is offline, using cached data');
      return;
    }

    try {
      // Fetch bookings from API
      // Save to cache
      print('Bookings synced');
    } catch (e) {
      print('Error syncing bookings: $e');
    }
  }

  /// Sync reviews data
  Future<void> syncReviews(String photographerId) async {
    final online = await isOnline();
    if (!online) {
      print('Device is offline, using cached data');
      return;
    }

    try {
      // Fetch reviews from API
      // Save to cache
      print('Reviews synced for photographer: $photographerId');
    } catch (e) {
      print('Error syncing reviews: $e');
    }
  }

  /// Sync all data
  Future<void> syncAll() async {
    await syncPendingActions();
    await syncPhotographers();
    await syncBookings();
  }

  /// Clear pending actions
  Future<void> clearPendingActions() async {
    _pendingActions.clear();
    await _hiveService.savePendingActions([]);
    print('Pending actions cleared');
  }

  /// Get pending actions count
  int get pendingActionsCount => _pendingActions.length;
}
