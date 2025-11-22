import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../services/media/image_service.dart';

/// User State
class UserState {
  final bool isLoading;
  final String? error;
  final User? user;
  final bool isUpdating;

  const UserState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isUpdating = false,
  });

  UserState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    bool? isUpdating,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

/// User Notifier
class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState());

  /// Get user profile
  Future<void> getProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement with actual UseCase
      // For now, return mock data
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user data
      final user = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        phone: '0501234567',
        role: 'client',
        isActive: true,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      // TODO: Implement with actual UseCase
      await Future.delayed(const Duration(seconds: 1));

      final updatedUser = User(
        id: state.user?.id ?? '',
        name: name,
        email: email,
        phone: phone,
        role: state.user?.role ?? 'client',
        avatar: state.user?.avatar,
        isActive: state.user?.isActive ?? true,
        createdAt: state.user?.createdAt ?? DateTime.now(),
      );

      state = state.copyWith(
        isUpdating: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Upload avatar
  Future<void> uploadAvatar(File file) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      // Compress image
      final imageService = ImageService();
      final compressed = await imageService.compressImage(file, quality: 80);

      if (compressed == null) {
        throw Exception('Failed to compress image');
      }

      // TODO: Upload to server
      await Future.delayed(const Duration(seconds: 2));

      // Mock avatar URL
      const avatarUrl = 'https://via.placeholder.com/150';

      final updatedUser = User(
        id: state.user?.id ?? '',
        name: state.user?.name ?? '',
        email: state.user?.email ?? '',
        phone: state.user?.phone,
        role: state.user?.role ?? 'client',
        avatar: avatarUrl,
        isActive: state.user?.isActive ?? true,
        createdAt: state.user?.createdAt ?? DateTime.now(),
      );

      state = state.copyWith(
        isUpdating: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear user data
  void clearUser() {
    state = const UserState();
  }
}

/// User Provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});
