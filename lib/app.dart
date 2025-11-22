import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/core/theme/app_theme.dart';
import 'package:hajzy/core/theme/theme_provider.dart';
import 'package:hajzy/features/auth/presentation/pages/login_page.dart';
import 'package:hajzy/features/auth/presentation/pages/register_page.dart';
import 'package:hajzy/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:hajzy/features/auth/presentation/pages/verify_reset_code_page.dart';
import 'package:hajzy/features/auth/presentation/pages/reset_password_page.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/features/booking/presentation/pages/booking_page.dart';
import 'package:hajzy/features/booking/presentation/pages/my_bookings_page.dart';
import 'package:hajzy/features/booking/presentation/widgets/booking_notification_listener.dart';
import 'package:hajzy/features/chat/presentation/pages/conversations_list_page.dart';
import 'package:hajzy/features/chat/presentation/pages/chat_page.dart';
import 'package:hajzy/features/main/presentation/pages/main_navigation_page.dart';
import 'package:hajzy/features/booking/presentation/pages/booking_details_page.dart';
import 'package:hajzy/features/photographer/presentation/pages/photographer_details_page.dart';
import 'package:hajzy/features/photographer/presentation/pages/photographers_list_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/bookings_management_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/photographer_dashboard_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/complete_profile_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/portfolio_management_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/package_management_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/calendar_management_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/reviews_section_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/earnings_report_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/photographer_settings_page.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/pages/verification_request_screen.dart';
import 'package:hajzy/features/profile/presentation/pages/user_profile_page.dart';
import 'package:hajzy/features/profile/presentation/pages/help_center_page.dart';
import 'package:hajzy/features/profile/presentation/pages/contact_us_page.dart';
import 'package:hajzy/features/profile/presentation/pages/about_app_page.dart';
import 'package:hajzy/features/profile/presentation/pages/appearance_settings_page.dart';
import 'package:hajzy/features/profile/presentation/pages/subscription_page.dart';
import 'package:hajzy/features/profile/presentation/pages/payment_methods_page.dart';
import 'package:hajzy/features/notifications/presentation/pages/notifications_page.dart';
import 'package:hajzy/features/notifications/presentation/widgets/notification_listener.dart'
    as notif;
import 'package:hajzy/features/auth/presentation/pages/banned_screen.dart';
import 'package:hajzy/main.dart' show navigatorKey;
import 'package:hajzy/core/providers/offline_provider.dart';

class HajzyApp extends ConsumerStatefulWidget {
  const HajzyApp({super.key});

  @override
  ConsumerState<HajzyApp> createState() => _HajzyAppState();
}

class _HajzyAppState extends ConsumerState<HajzyApp> {
  @override
  void initState() {
    super.initState();
    // بدء المزامنة التلقائية
    Future.microtask(() {
      try {
        ref.read(syncServiceProvider).startAutoSync();
      } catch (e) {
        // تجاهل الأخطاء في حالة عدم توفر الخدمة
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(syncServiceProvider).stopAutoSync();
    } catch (e) {
      // تجاهل الأخطاء
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return notif.NotificationListener(
      child: BookingNotificationListener(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.themeMode,
          home: const SplashScreen(),
          routes: {
            '/home': (context) => const MainNavigationPage(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/profile': (context) => const UserProfilePage(),
            '/photographers': (context) => const PhotographersListPage(),
            '/photographer-dashboard': (context) =>
                const PhotographerDashboardPage(),
            '/complete-profile': (context) => const CompleteProfilePage(),
            '/bookings-management': (context) => const BookingsManagementPage(),
            '/my-bookings': (context) => const MyBookingsPage(),
            '/notifications': (context) => const NotificationsPage(),
            '/help-center': (context) => const HelpCenterPage(),
            '/contact-us': (context) => const ContactUsPage(),
            '/about-app': (context) => const AboutAppPage(),
            '/appearance-settings': (context) => const AppearanceSettingsPage(),
            '/subscription': (context) => const SubscriptionPage(),
            '/payment-methods': (context) => const PaymentMethodsPage(),
            '/banned': (context) => const BannedScreen(),
            '/verification-request': (context) =>
                const VerificationRequestScreen(),
          },
          onGenerateRoute: (settings) {
            // التعامل مع المسارات الديناميكية
            if (settings.name?.startsWith('/photographer/') ?? false) {
              final id = settings.name!.split('/').last;
              return MaterialPageRoute(
                builder: (context) =>
                    PhotographerDetailsPage(photographerId: id),
              );
            }
            if (settings.name?.startsWith('/booking/') ?? false) {
              final parts = settings.name!.split('/');
              if (parts.length >= 3 && parts[2] != '') {
                final id = parts[2];
                return MaterialPageRoute(
                  builder: (context) => BookingPage(photographerId: id),
                );
              }
            }
            if (settings.name?.startsWith('/booking-details/') ?? false) {
              final id = settings.name!.split('/').last;
              return MaterialPageRoute(
                builder: (context) => BookingDetailsPage(bookingId: id),
              );
            }
            // Chat route with arguments
            if (settings.name == '/chat') {
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return MaterialPageRoute(
                  builder: (context) => ChatPage(
                    conversationId: args['conversationId'] ?? '',
                    otherUserId: args['otherUserId'] ?? '',
                    otherUserName: args['otherUserName'] ?? '',
                    otherUserAvatar: args['otherUserAvatar'],
                  ),
                );
              }
            }

            // Password Reset Routes with arguments
            if (settings.name == '/verify-reset-code') {
              final email = settings.arguments as String?;
              if (email != null) {
                return MaterialPageRoute(
                  builder: (context) => VerifyResetCodePage(email: email),
                );
              }
            }
            if (settings.name == '/reset-password') {
              final args = settings.arguments as Map<String, String>?;
              if (args != null &&
                  args['email'] != null &&
                  args['code'] != null) {
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordPage(
                    email: args['email']!,
                    code: args['code']!,
                  ),
                );
              }
            }

            // Photographer Dashboard Routes
            switch (settings.name) {
              case '/portfolio-management':
                return MaterialPageRoute(
                  builder: (context) => const PortfolioManagementPage(),
                );
              case '/package-management':
                return MaterialPageRoute(
                  builder: (context) => const PackageManagementPageNew(),
                );
              case '/calendar-management':
                return MaterialPageRoute(
                  builder: (context) => const CalendarManagementPage(),
                );
              case '/reviews-section':
                return MaterialPageRoute(
                  builder: (context) => const ReviewsSectionPage(),
                );
              case '/earnings-report':
                return MaterialPageRoute(
                  builder: (context) => const EarningsReportPage(),
                );
              case '/photographer-settings':
                return MaterialPageRoute(
                  builder: (context) => const PhotographerSettingsPage(),
                );
              case '/conversations':
                return MaterialPageRoute(
                  builder: (context) => const ConversationsListPage(),
                );
            }

            return null;
          },
        ),
      ),
    );
  }
}

/// Splash Screen with Auto-Login
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      print('═══════════════════════════════════════════════════');
      print('DEBUG Splash: Starting login status check...');
      print('═══════════════════════════════════════════════════');

      // Wait for auth provider to initialize
      print('⏳ Waiting for auth provider to initialize...');

      // Poll until initialized or timeout
      int attempts = 0;
      const maxAttempts = 50; // 5 seconds max (50 * 100ms)

      while (attempts < maxAttempts) {
        if (!mounted) {
          print('DEBUG Splash: Widget not mounted, aborting');
          return;
        }

        final authState = ref.read(authProvider);

        if (authState.isInitialized) {
          print('✅ Auth provider initialized after ${attempts * 100}ms');
          break;
        }

        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (attempts >= maxAttempts) {
        print('⚠️ Auth provider initialization timeout');
      }

      if (!mounted) {
        print('DEBUG Splash: Widget not mounted, aborting');
        return;
      }

      // Get the auth state - it should have loaded saved session by now
      final authState = ref.read(authProvider);

      print('DEBUG Splash: Auth state retrieved');
      print('  - isInitialized: ${authState.isInitialized}');
      print('  - isLoading: ${authState.isLoading}');
      print('  - isAuthenticated: ${authState.isAuthenticated}');
      print('  - user exists: ${authState.user != null}');
      print('  - user name: ${authState.user?.name}');
      print('  - user role: ${authState.user?.role}');
      print('  - error: ${authState.error}');

      // Wait for splash animation (minimum 2 seconds total)
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        print('DEBUG Splash: Widget not mounted after delay, aborting');
        return;
      }

      if (authState.isAuthenticated && authState.user != null) {
        // User is logged in, check role and navigate accordingly
        final user = authState.user!;

        print('✅ DEBUG Splash: User IS authenticated');
        print('  - User: ${user.name}');
        print('  - Role: ${user.role}');

        if (user.role == 'photographer') {
          // Check if photographer has completed profile
          print('🎯 DEBUG Splash: Checking photographer profile...');
          try {
            await ref
                .read(photographersProvider.notifier)
                .getMyPhotographerProfile();
            final photographer = ref
                .read(photographersProvider)
                .selectedPhotographer;

            if (photographer != null) {
              // Profile exists, navigate to dashboard
              print(
                '✅ DEBUG Splash: Profile exists, navigating to PHOTOGRAPHER DASHBOARD',
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const PhotographerDashboardPage(),
                ),
              );
            } else {
              // Profile doesn't exist, navigate to complete profile
              print(
                '⚠️ DEBUG Splash: Profile not found, navigating to COMPLETE PROFILE',
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
              );
            }
          } catch (e) {
            // Error or profile not found, navigate to complete profile
            print('⚠️ DEBUG Splash: Error checking profile: $e');
            print('🎯 DEBUG Splash: Navigating to COMPLETE PROFILE');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
            );
          }
        } else {
          // Navigate to main navigation page (for clients)
          print('🎯 DEBUG Splash: Navigating to MAIN NAVIGATION PAGE');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationPage()),
          );
        }
      } else {
        // User is not logged in, go to login
        print('❌ DEBUG Splash: User NOT authenticated');
        print('🎯 DEBUG Splash: Navigating to LOGIN PAGE');
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }

      print('═══════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      // Error checking login status, go to login
      print('❌ DEBUG Splash: ERROR checking login status');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('═══════════════════════════════════════════════════');

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // استخدام الثيم الحالي
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF667eea).withValues(alpha: 0.8),
                    const Color(0xFF764ba2).withValues(alpha: 0.8),
                  ]
                : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                'احجز مصورتك المفضلة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: isDark ? 0.8 : 0.7),
                ),
              ),
              const SizedBox(height: 48),
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
