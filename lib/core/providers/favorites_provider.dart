import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/network/api_client.dart';
import 'package:hajzy/core/constants/api_endpoints.dart';
import 'package:hajzy/core/services/offline_service.dart';
import 'package:hajzy/features/photographer/data/datasources/photographer_local_datasource.dart';
import 'dart:developer' as developer;

// Provider للمفضلة
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<String>> {
  final ApiClient _apiClient = ApiClient();
  final OfflineService _offlineService = OfflineService();
  final PhotographerLocalDataSource _localDataSource;

  FavoritesNotifier() 
      : _localDataSource = PhotographerLocalDataSource(OfflineService()),
        super([]) {
    _loadFavorites();
  }

  // تحميل المفضلة من الخادم أو محلياً
  Future<void> _loadFavorites() async {
    try {
      developer.log('📥 Loading favorites...', name: 'FavoritesProvider');
      
      final isOnline = await _offlineService.isOnline();
      
      if (isOnline) {
        // تحميل من السيرفر
        try {
          final response = await _apiClient.get(ApiEndpoints.getFavorites);
          
          if (response.data['success'] == true) {
            final List<dynamic> data = response.data['data'] ?? [];
            state = data.map((item) => item['_id'].toString()).toList();
            developer.log('✅ Loaded ${state.length} favorites from server', name: 'FavoritesProvider');
          }
        } catch (e) {
          // فشل التحميل من السيرفر، نحاول من الكاش
          developer.log('⚠️ Failed to load from server, trying cache...', name: 'FavoritesProvider');
          final localFavorites = await _localDataSource.getFavorites();
          state = localFavorites.map((item) => item['id'].toString()).toList();
          developer.log('✅ Loaded ${state.length} favorites from cache', name: 'FavoritesProvider');
        }
      } else {
        // تحميل من التخزين المحلي
        final localFavorites = await _localDataSource.getFavorites();
        state = localFavorites.map((item) => item['id'].toString()).toList();
        developer.log('✅ Loaded ${state.length} favorites from local storage', name: 'FavoritesProvider');
      }
    } catch (e) {
      developer.log('⚠️ Could not load favorites, starting with empty list', name: 'FavoritesProvider');
      // Keep empty state on error - لا نعرض خطأ للمستخدم
      state = [];
    }
  }

  // إضافة/إزالة من المفضلة (يعمل أوف لاين)
  Future<void> toggle(String photographerId) async {
    final wasFavorite = state.contains(photographerId);
    
    // Optimistic update
    if (wasFavorite) {
      state = state.where((id) => id != photographerId).toList();
    } else {
      state = [...state, photographerId];
    }

    try {
      developer.log('${wasFavorite ? '❌' : '❤️'} Toggling favorite: $photographerId', name: 'FavoritesProvider');
      
      // حفظ محلياً أولاً
      await _localDataSource.toggleFavorite(photographerId, !wasFavorite);
      
      final isOnline = await _offlineService.isOnline();
      
      if (isOnline) {
        // محاولة المزامنة مع السيرفر
        if (wasFavorite) {
          await _apiClient.delete(ApiEndpoints.removeFromFavorites(photographerId));
          developer.log('✅ Removed from favorites (synced)', name: 'FavoritesProvider');
        } else {
          await _apiClient.post(
            ApiEndpoints.addToFavorites(photographerId),
            data: {},
          );
          developer.log('✅ Added to favorites (synced)', name: 'FavoritesProvider');
        }
      } else {
        developer.log('📴 Saved locally, will sync when online', name: 'FavoritesProvider');
      }
    } catch (e) {
      developer.log('❌ Error toggling favorite: $e', name: 'FavoritesProvider');
      
      // Revert on error
      if (wasFavorite) {
        state = [...state, photographerId];
      } else {
        state = state.where((id) => id != photographerId).toList();
      }
      
      rethrow;
    }
  }

  // التحقق من وجود في المفضلة
  bool isFavorite(String photographerId) {
    return state.contains(photographerId);
  }

  // إعادة تحميل المفضلة
  Future<void> refresh() async {
    await _loadFavorites();
  }
}
