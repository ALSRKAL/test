import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/delete_avatar_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/get_user_statistics_usecase.dart';
import '../../domain/usecases/update_notification_settings_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';

// API Client Provider
final apiClientProvider = Provider((ref) => ApiClient());

// Network Info Provider
final networkInfoProvider = Provider((ref) => NetworkInfoImpl(Connectivity()));

// Providers
final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSourceImpl();
});

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRemoteDataSourceImpl(apiClient: apiClient);
});

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Use Cases
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(profileRepositoryProvider));
});

final deleteAvatarUseCaseProvider = Provider<DeleteAvatarUseCase>((ref) {
  return DeleteAvatarUseCase(ref.watch(profileRepositoryProvider));
});

final updateNotificationSettingsUseCaseProvider =
    Provider<UpdateNotificationSettingsUseCase>((ref) {
  return UpdateNotificationSettingsUseCase(ref.watch(profileRepositoryProvider));
});

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(profileRepositoryProvider));
});

final getUserStatisticsUseCaseProvider = Provider<GetUserStatisticsUseCase>((ref) {
  return GetUserStatisticsUseCase(ref.watch(profileRepositoryProvider));
});

// State
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool isUpdating;
  final bool isUploadingAvatar;

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
    this.isUploadingAvatar = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isUploadingAvatar,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    );
  }
}

// Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final DeleteAvatarUseCase deleteAvatarUseCase;
  final UpdateNotificationSettingsUseCase updateNotificationSettingsUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final GetUserStatisticsUseCase getUserStatisticsUseCase;

  ProfileNotifier({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
    required this.updateNotificationSettingsUseCase,
    required this.deleteAccountUseCase,
    required this.getUserStatisticsUseCase,
  }) : super(ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await getProfileUseCase();
      
      // تحديث الإحصائيات من الباك اند
      try {
        final statistics = await getUserStatisticsUseCase();
        final updatedProfile = profile.copyWith(statistics: statistics);
        state = state.copyWith(
          isLoading: false,
          profile: updatedProfile,
          error: null,
        );
      } catch (e) {
        // إذا فشل جلب الإحصائيات، استخدم البيانات الموجودة في البروفايل
        print('Failed to load statistics: $e');
        state = state.copyWith(
          isLoading: false,
          profile: profile,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshStatistics() async {
    if (state.profile == null) return;

    try {
      final statistics = await getUserStatisticsUseCase();
      final updatedProfile = state.profile!.copyWith(statistics: statistics);
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      print('Failed to refresh statistics: $e');
    }
  }

  Future<bool> updateProfile({String? name, String? phone}) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final profile = await updateProfileUseCase(name: name, phone: phone);
      state = state.copyWith(
        isUpdating: false,
        profile: profile,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    state = state.copyWith(isUploadingAvatar: true, error: null);

    try {
      final avatarUrl = await uploadAvatarUseCase(imageFile);
      if (state.profile != null) {
        state = state.copyWith(
          isUploadingAvatar: false,
          profile: state.profile!.copyWith(avatar: avatarUrl),
          error: null,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploadingAvatar: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteAvatar() async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await deleteAvatarUseCase();
      if (state.profile != null) {
        state = state.copyWith(
          isUpdating: false,
          profile: state.profile!.copyWith(avatar: null),
          error: null,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateNotificationSettings(
    NotificationSettings settings,
  ) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await updateNotificationSettingsUseCase(settings);
      if (state.profile != null) {
        state = state.copyWith(
          isUpdating: false,
          profile: state.profile!.copyWith(
            notificationSettings: settings,
          ),
          error: null,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      await deleteAccountUseCase();
      state = ProfileState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(
    getProfileUseCase: ref.watch(getProfileUseCaseProvider),
    updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    uploadAvatarUseCase: ref.watch(uploadAvatarUseCaseProvider),
    deleteAvatarUseCase: ref.watch(deleteAvatarUseCaseProvider),
    updateNotificationSettingsUseCase:
        ref.watch(updateNotificationSettingsUseCaseProvider),
    deleteAccountUseCase: ref.watch(deleteAccountUseCaseProvider),
    getUserStatisticsUseCase: ref.watch(getUserStatisticsUseCaseProvider),
  );
});
