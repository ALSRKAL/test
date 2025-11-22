import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../../../core/network/api_client.dart';
import '../../../../services/notification/notification_service.dart';
import '../../../../services/socket/socket_service.dart';
import '../../../../core/errors/auth_error_type.dart';
import '../../../../core/errors/auth_error_handler.dart';
import '../../../../main.dart';

// Auth State
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final AuthErrorInfo? errorInfo; // معلومات الخطأ المفصلة
  final User? user;
  final bool isInitialized; // New field to track if initial load is complete

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.errorInfo,
    this.user,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    AuthErrorInfo? errorInfo,
    User? user,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      errorInfo: errorInfo,
      user: user ?? this.user,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthLocalDataSource localDataSource;

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.localDataSource,
  }) : super(const AuthState()) {
    // Load saved auth state on initialization
    _loadSavedAuthState();

    // Listen for user ban events
    ApiClient.onUserBanned = () {
      print('🚨 User banned! Logging out...');
      logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/banned',
        (route) => false,
      );
    };

    // Listen for token expiration events (401)
    ApiClient.onTokenExpired = () {
      print('🚨 Token expired and refresh failed! Logging out...');
      logout();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    };
  }

  // Load saved authentication state
  Future<void> _loadSavedAuthState() async {
    try {
      print('═══════════════════════════════════════════════════');
      print('🔍 DEBUG Auth Provider: Loading saved auth state...');
      print('═══════════════════════════════════════════════════');

      final user = await localDataSource.getUser();
      final accessToken = await localDataSource.getAccessToken();
      final refreshToken = await localDataSource.getRefreshToken();

      print('📦 Data from storage:');
      print('  - User: ${user?.name}');
      print('  - User Role: ${user?.role}');
      print('  - Access Token exists: ${accessToken != null}');
      print('  - Access Token length: ${accessToken?.length ?? 0}');
      print('  - Refresh Token exists: ${refreshToken != null}');

      if (user != null && accessToken != null) {
        // Check if user wants to be remembered
        final rememberMe = await localDataSource.getRememberMe();
        print('  - Remember Me: $rememberMe');

        if (!rememberMe) {
          print('❌ User chose NOT to be remembered, clearing session');
          await localDataSource.clearAuth();
          state = state.copyWith(isInitialized: true);
          print('═══════════════════════════════════════════════════');
          return;
        }

        // User is logged in and wants to be remembered, restore state
        print('✅ Restoring user session...');
        ApiClient.setAccessToken(accessToken);
        print('✅ Access token set in ApiClient');

        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isInitialized: true,
        );

        // Set OneSignal external user ID
        await NotificationService().setExternalUserId(user.id);

        // Connect Socket for real-time messaging
        try {
          print('🔌 [AuthProvider] Attempting to connect Socket...');
          print('   User ID: ${user.id}');
          final socketService = SocketService();
          print('🔌 [AuthProvider] SocketService instance obtained');
          await socketService.connect(userId: user.id);
          print('✅ [AuthProvider] Socket connect() completed');
          print('   Socket connected: ${socketService.isConnected}');
          // Join bookings room for notifications
          socketService.joinBookingsRoom(user.id);

          // Listen for ban event
          socketService.onUserBanned((data) {
            print('🚨 Received user_banned event from socket: $data');
            ApiClient.onUserBanned?.call();
          });

          // Listen for unblock event
          socketService.onUserUnblocked((data) {
            print('✅ Received user_unblocked event from socket: $data');
            // User has been unblocked, navigate away from banned screen if on it
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/main',
              (route) => false,
            );
          });

          print('✅ [AuthProvider] Socket connected for user: ${user.id}');
          print('✅ [AuthProvider] Joined bookings room for notifications');
        } catch (e, stackTrace) {
          print('⚠️ [AuthProvider] Socket connection failed: $e');
          print('   Stack trace: $stackTrace');
        }

        print('✅ User session restored successfully!');
        print('  - State isAuthenticated: ${state.isAuthenticated}');
        print('  - State user: ${state.user?.name}');
        print('  - State user role: ${state.user?.role}');
        print('  - State isInitialized: ${state.isInitialized}');
      } else {
        print('❌ No saved session found (user or token missing)');
        state = state.copyWith(isInitialized: true);
      }

      print('═══════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      // Error loading saved state, user needs to login again
      print('❌ ERROR loading saved state: $e');
      print('StackTrace: $stackTrace');
      print('═══════════════════════════════════════════════════');
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorInfo: null);

    try {
      print('DEBUG Auth Provider: Logging in with rememberMe: $rememberMe');

      // Save remember me preference
      await localDataSource.saveRememberMe(rememberMe);

      final user = await loginUseCase.call(email, password);

      print(
        'DEBUG Auth Provider: Login successful, user: ${user.name}, role: ${user.role}',
      );

      // Set OneSignal external user ID
      await NotificationService().setExternalUserId(user.id);

      // Set user tags for targeting
      await NotificationService().sendTag('user_role', user.role);

      // Connect Socket for real-time messaging
      try {
        final socketService = SocketService();
        await socketService.connect(userId: user.id);
        // Join bookings room for notifications
        socketService.joinBookingsRoom(user.id);

        // Listen for ban event
        socketService.onUserBanned((data) {
          print('🚨 Received user_banned event from socket: $data');
          ApiClient.onUserBanned?.call();
        });

        // Listen for unblock event
        socketService.onUserUnblocked((data) {
          print('✅ Received user_unblocked event from socket: $data');
          // User has been unblocked, navigate away from banned screen if on it
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/main',
            (route) => false,
          );
        });

        print('✅ Socket connected for user: ${user.id}');
        print('✅ Joined bookings room for notifications');
      } catch (e) {
        print('⚠️ Socket connection failed: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );

      print(
        'DEBUG Auth Provider: State updated, isAuthenticated: ${state.isAuthenticated}',
      );
    } catch (e) {
      print('DEBUG Auth Provider: Login failed: $e');
      // استخدام معالج الأخطاء الذكي
      final errorInfo = AuthErrorHandler.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: errorInfo.message,
        errorInfo: errorInfo,
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorInfo: null);

    try {
      final user = await registerUseCase.call(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      // Set OneSignal external user ID
      await NotificationService().setExternalUserId(user.id);

      // Set user tags for targeting
      await NotificationService().sendTag('user_role', user.role);

      // Connect Socket for real-time messaging
      try {
        final socketService = SocketService();
        await socketService.connect(userId: user.id);
        // Join bookings room for notifications
        socketService.joinBookingsRoom(user.id);

        // Listen for ban event
        socketService.onUserBanned((data) {
          print('🚨 Received user_banned event from socket: $data');
          ApiClient.onUserBanned?.call();
        });

        // Listen for unblock event
        socketService.onUserUnblocked((data) {
          print('✅ Received user_unblocked event from socket: $data');
          // User has been unblocked, navigate away from banned screen if on it
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/main',
            (route) => false,
          );
        });

        print('✅ Socket connected for user: ${user.id}');
        print('✅ Joined bookings room for notifications');
      } catch (e) {
        print('⚠️ Socket connection failed: $e');
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      // استخدام معالج الأخطاء الذكي
      final errorInfo = AuthErrorHandler.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: errorInfo.message,
        errorInfo: errorInfo,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      // Remove OneSignal external user ID
      await NotificationService().removeExternalUserId();

      await logoutUseCase.call();
      state = const AuthState();
    } catch (e) {
      // تنظيف رسالة الخطأ من كلمة Exception
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  // Update user profile (name, phone)
  Future<void> updateUserProfile({String? name, String? phone}) async {
    if (state.user == null) return;

    try {
      // Call API to update user profile
      final apiClient = ApiClient();
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;

      final response = await apiClient.put('/users/profile', data: data);

      // Update local state
      final userData = response.data['data'];
      final updatedUser = User(
        id: userData['_id'],
        name: userData['name'],
        email: userData['email'],
        phone: userData['phone'],
        role: userData['role'],
        avatar: userData['avatar'],
        isActive: !(userData['isBlocked'] ?? false),
        createdAt: DateTime.parse(userData['createdAt']),
      );

      state = state.copyWith(user: updatedUser);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload avatar
  Future<String> uploadAvatar(String imagePath) async {
    if (state.user == null) throw Exception('User not authenticated');

    try {
      final apiClient = ApiClient();

      // Create FormData
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imagePath),
      });

      final response = await apiClient.post('/users/avatar', data: formData);

      final avatarUrl = response.data['data']['avatar'];

      // Update local state
      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        phone: state.user!.phone,
        role: state.user!.role,
        avatar: avatarUrl,
        isActive: state.user!.isActive,
        createdAt: state.user!.createdAt,
      );

      state = state.copyWith(user: updatedUser);

      return avatarUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Delete avatar
  Future<void> deleteAvatar() async {
    if (state.user == null) return;

    try {
      final apiClient = ApiClient();
      await apiClient.delete('/users/avatar');

      // Update local state
      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        phone: state.user!.phone,
        role: state.user!.role,
        avatar: null,
        isActive: state.user!.isActive,
        createdAt: state.user!.createdAt,
      );

      state = state.copyWith(user: updatedUser);
    } catch (e) {
      throw Exception('Failed to delete avatar: $e');
    }
  }

  // Update user role after creating photographer profile
  void updateUserRole(String newRole) {
    print('DEBUG Auth Provider: updateUserRole called with role: $newRole');
    if (state.user != null) {
      print('DEBUG Auth Provider: Current user role: ${state.user!.role}');

      final updatedUser = User(
        id: state.user!.id,
        name: state.user!.name,
        email: state.user!.email,
        phone: state.user!.phone,
        role: newRole,
        avatar: state.user!.avatar,
        isActive: state.user!.isActive,
        createdAt: state.user!.createdAt,
      );

      state = state.copyWith(user: updatedUser);

      print('DEBUG Auth Provider: User role updated to: ${state.user!.role}');

      // Note: We don't save to local storage here because saveUser expects UserModel
      // The user will be updated on next login or when they refresh the app
    } else {
      print('DEBUG Auth Provider: No user in state, cannot update role');
    }
  }

  void clearError() {
    state = state.copyWith(error: null, errorInfo: null);
  }
}

// Providers
final authRepositoryProvider = Provider((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(ApiClient()),
    localDataSource: AuthLocalDataSourceImpl(const FlutterSecureStorage()),
  );
});

final loginUseCaseProvider = Provider((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final authLocalDataSourceProvider = Provider((ref) {
  return AuthLocalDataSourceImpl(const FlutterSecureStorage());
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    registerUseCase: ref.read(registerUseCaseProvider),
    logoutUseCase: ref.read(logoutUseCaseProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  );
});
