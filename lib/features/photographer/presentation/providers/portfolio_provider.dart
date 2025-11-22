import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/photographer.dart';
import '../../data/datasources/photographer_remote_datasource.dart';
import '../../../../core/network/api_client.dart';

// Portfolio State
class PortfolioState {
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? uploadingType; // 'image' or 'video'
  final String? error;
  final List<PortfolioImage> images;
  final PortfolioVideo? video;
  final String? photographerId;
  final Set<String> deletingItems; // IDs of items being deleted

  const PortfolioState({
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.uploadingType,
    this.error,
    this.images = const [],
    this.video,
    this.photographerId,
    this.deletingItems = const {},
  });

  PortfolioState copyWith({
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? uploadingType,
    String? error,
    List<PortfolioImage>? images,
    PortfolioVideo? video,
    String? photographerId,
    Set<String>? deletingItems,
    bool clearError = false,
    bool clearUploadingType = false,
    bool clearVideo = false,
  }) {
    return PortfolioState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadingType: clearUploadingType ? null : (uploadingType ?? this.uploadingType),
      error: clearError ? null : error,
      images: images ?? this.images,
      video: clearVideo ? null : (video ?? this.video),
      photographerId: photographerId ?? this.photographerId,
      deletingItems: deletingItems ?? this.deletingItems,
    );
  }

  int get imageCount => images.length;
  bool get hasVideo => video != null;
  bool get canAddImages => imageCount < 20;
  int get remainingImages => 20 - imageCount;
  
  bool isDeleting(String id) => deletingItems.contains(id);
}

// Portfolio Notifier
class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final PhotographerRemoteDataSource remoteDataSource;

  PortfolioNotifier({
    required this.remoteDataSource,
  }) : super(const PortfolioState());

  // Load portfolio for current photographer
  Future<void> loadPortfolio(String photographerId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final photographer = await remoteDataSource.getPhotographerById(photographerId);
      
      state = state.copyWith(
        isLoading: false,
        images: photographer.portfolio.images,
        video: photographer.portfolio.video,
        photographerId: photographerId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل المعرض: ${e.toString()}',
      );
    }
  }

  // Load current user's photographer profile
  Future<void> loadMyProfile() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final photographer = await remoteDataSource.getMyPhotographerProfile();
      
      if (photographer != null) {
        // Check if video exists, if not clear it
        final hasVideo = photographer.portfolio.video != null;
        
        state = state.copyWith(
          isLoading: false,
          images: photographer.portfolio.images,
          video: photographer.portfolio.video,
          photographerId: photographer.id,
          clearVideo: !hasVideo,
        );
      } else {
        // Profile not found - this is expected for new photographers
        state = state.copyWith(
          isLoading: false,
          images: [],
          clearVideo: true,
          photographerId: null,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل المعرض: ${e.toString()}',
      );
    }
  }

  // Upload images
  Future<bool> uploadImages(List<File> files) async {
    if (files.isEmpty) return false;
    
    if (state.imageCount + files.length > 20) {
      state = state.copyWith(
        error: 'لا يمكن إضافة أكثر من 20 صورة',
      );
      return false;
    }

    // Create temporary placeholder images for optimistic UI
    final tempImages = files.asMap().entries.map((entry) {
      return PortfolioImage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
        url: entry.value.path, // Use local file path temporarily
        publicId: '',
        uploadedAt: DateTime.now(),
      );
    }).toList();

    try {
      // Optimistic update: Show images immediately
      state = state.copyWith(
        isUploading: true,
        uploadingType: 'image',
        uploadProgress: 0.0,
        clearError: true,
        images: [...state.images, ...tempImages],
      );

      // Simulate progress
      _simulateProgress();

      // Upload images in background
      await remoteDataSource.uploadImages(files.map((f) => f.path).toList());

      // Mark upload as complete
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        clearUploadingType: true,
      );

      // Reload portfolio from server to get real data with IDs
      await loadMyProfile();

      return true;
    } catch (e) {
      // Rollback: Remove temporary images on failure
      final rollbackImages = state.images
          .where((img) => img.id != null && !(img.id?.startsWith('temp_') ?? false))
          .toList();
      
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: 'فشل رفع الصور: ${e.toString()}',
        clearUploadingType: true,
        images: rollbackImages,
      );
      return false;
    }
  }

  // Upload video
  Future<bool> uploadVideo(File file) async {
    // Create temporary placeholder video for optimistic UI
    final tempVideo = PortfolioVideo(
      url: file.path, // Use local file path temporarily
      publicId: '',
      thumbnail: file.path, // Use local path as thumbnail
      duration: 0,
      size: 0,
      uploadedAt: DateTime.now(),
    );

    // Store old video in case we need to rollback
    final oldVideo = state.video;

    try {
      // Optimistic update: Show video immediately
      state = state.copyWith(
        isUploading: true,
        uploadingType: 'video',
        uploadProgress: 0.0,
        clearError: true,
        video: tempVideo,
      );

      // Simulate progress
      _simulateProgress();

      // Upload video in background
      await remoteDataSource.uploadVideo(file.path);

      // Mark upload as complete
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        clearUploadingType: true,
      );

      // Reload portfolio from server to get real data
      await loadMyProfile();

      return true;
    } catch (e) {
      // Rollback: Restore old video on failure
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: 'فشل رفع الفيديو: ${e.toString()}',
        clearUploadingType: true,
        video: oldVideo,
        clearVideo: oldVideo == null,
      );
      return false;
    }
  }

  // Delete image
  Future<bool> deleteImage(String imageId) async {
    // Store image in case we need to rollback
    final imageToDelete = state.images.firstWhere(
      (img) => img.id == imageId,
      orElse: () => PortfolioImage(
        id: imageId,
        url: '',
        publicId: '',
        uploadedAt: DateTime.now(),
      ),
    );
    final imageIndex = state.images.indexWhere((img) => img.id == imageId);

    try {
      // Optimistic update: Remove image immediately
      final updatedImages = state.images.where((img) => img.id != imageId).toList();
      final newDeletingItems = Set<String>.from(state.deletingItems)..add(imageId);
      
      state = state.copyWith(
        images: updatedImages,
        deletingItems: newDeletingItems,
      );
      
      // Wait a bit for animation
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Delete from server in background
      await remoteDataSource.deleteImage(imageId);

      // Clear deleting state
      final clearedDeletingItems = Set<String>.from(state.deletingItems)..remove(imageId);
      state = state.copyWith(deletingItems: clearedDeletingItems);

      // Reload portfolio from server to sync (in background)
      loadMyProfile();

      return true;
    } catch (e) {
      // Rollback: Restore image on failure
      final restoredImages = List<PortfolioImage>.from(state.images);
      if (imageIndex >= 0 && imageIndex <= restoredImages.length) {
        restoredImages.insert(imageIndex, imageToDelete);
      } else {
        restoredImages.add(imageToDelete);
      }
      
      final clearedDeletingItems = Set<String>.from(state.deletingItems)..remove(imageId);
      state = state.copyWith(
        error: 'فشل حذف الصورة: ${e.toString()}',
        deletingItems: clearedDeletingItems,
        images: restoredImages,
      );
      return false;
    }
  }

  // Delete video
  Future<bool> deleteVideo(String videoId) async {
    // Store video in case we need to rollback
    final oldVideo = state.video;

    try {
      // Optimistic update: Remove video immediately
      final newDeletingItems = Set<String>.from(state.deletingItems)..add('video');
      state = state.copyWith(
        clearVideo: true,
        deletingItems: newDeletingItems,
      );
      
      // Wait a bit for animation
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Delete from server in background
      await remoteDataSource.deleteVideo();

      // Clear deleting state
      final clearedDeletingItems = Set<String>.from(state.deletingItems)..remove('video');
      state = state.copyWith(deletingItems: clearedDeletingItems);

      // Reload portfolio from server to sync (in background)
      loadMyProfile();

      return true;
    } catch (e) {
      // Rollback: Restore video on failure
      final clearedDeletingItems = Set<String>.from(state.deletingItems)..remove('video');
      state = state.copyWith(
        error: 'فشل حذف الفيديو: ${e.toString()}',
        deletingItems: clearedDeletingItems,
        video: oldVideo,
        clearVideo: oldVideo == null,
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Simulate upload progress
  void _simulateProgress() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (state.isUploading && state.uploadProgress < 0.9) {
        state = state.copyWith(
          uploadProgress: state.uploadProgress + 0.1,
        );
        _simulateProgress();
      }
    });
  }

}

// Providers - Simplified without repository layer for now
// In production, use proper repository pattern

final apiClientProvider = Provider((ref) => ApiClient());

final photographerRemoteDataSourceProvider = Provider((ref) {
  return PhotographerRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  return PortfolioNotifier(
    remoteDataSource: ref.watch(photographerRemoteDataSourceProvider),
  );
});
