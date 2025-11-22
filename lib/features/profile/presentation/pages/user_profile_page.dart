import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/widgets/loading/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_page.dart';
import 'edit_avatar_page.dart';
import 'favorites_page.dart';
import 'notification_settings_page.dart';
import 'appearance_settings_page.dart';
import 'help_center_page.dart';
import 'contact_us_page.dart';
import 'about_app_page.dart';
import '../widgets/profile_shimmer.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  @override
  void initState() {
    super.initState();
    // تحميل البيانات فقط إذا لم تكن موجودة
    Future.microtask(() {
      final currentState = ref.read(profileProvider);
      if (currentState.profile == null && !currentState.isLoading) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: profileState.isLoading && profileState.profile == null
          ? const ProfileShimmer()
          : profileState.error != null && profileState.profile == null
          ? _buildError(profileState.error!)
          : profileState.profile == null
          ? _buildEmptyState()
          : _buildProfileContent(profileState),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            error,
            style: TextStyle(fontSize: 16, color: context.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).loadProfile();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'لا توجد بيانات',
        style: TextStyle(color: context.textPrimary),
      ),
    );
  }

  Widget _buildProfileContent(ProfileState state) {
    final profile = state.profile!;

    return RefreshIndicator(
      onRefresh: () => ref.read(profileProvider.notifier).loadProfile(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Modern Header with Gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                      ),
                    ),
                  ),
                  // Profile Content
                  Positioned(
                    bottom: 20,
                    right: 0,
                    left: 0,
                    child: Column(
                      children: [
                        // Avatar with Border and Edit Button
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    profile.avatar != null &&
                                        profile.avatar!.isNotEmpty
                                    ? NetworkImage(profile.avatar!)
                                    : null,
                                child:
                                    profile.avatar == null ||
                                        profile.avatar!.isEmpty
                                    ? Text(
                                        profile.name.isNotEmpty
                                            ? profile.name[0].toUpperCase()
                                            : '؟',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditAvatarPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primaryGradientStart,
                                        AppColors.primaryGradientEnd,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          profile.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
            ],
          ),

          // Statistics Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.book_outlined,
                      label: 'الحجوزات',
                      value: '${profile.statistics.totalBookings}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.favorite_outline,
                      label: 'المفضلة',
                      value: '${profile.favorites.length}',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [context.cardShadow],
                    ),
                    child: Column(
                      children: [
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.palette_outlined,
                          title: 'المظهر',
                          subtitle: _getThemeModeName(ref),
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppearanceSettingsPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          color: context.dividerColor,
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.notifications_outlined,
                          title: 'إعدادات الإشعارات',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationSettingsPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          color: context.dividerColor,
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.favorite_outline,
                          title: 'المفضلة',
                          subtitle: '${profile.favorites.length} مصورة',
                          color: Colors.red,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoritesPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          color: context.dividerColor,
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.book_outlined,
                          title: 'حجوزاتي',
                          subtitle: '${profile.statistics.totalBookings} حجز',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(context, '/my-bookings');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'عام',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [context.cardShadow],
                    ),
                    child: Column(
                      children: [
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.help_outline,
                          title: 'مركز المساعدة',
                          subtitle: 'الأسئلة الشائعة',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpCenterPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          color: context.dividerColor,
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.phone_outlined,
                          title: 'تواصل معنا',
                          subtitle: 'الدعم الفني',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ContactUsPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          color: context.dividerColor,
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.info_outline,
                          title: 'عن التطبيق',
                          subtitle: 'الإصدار 1.0.0',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutAppPage(),
                              ),
                            );
                          },
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          color: context.dividerColor,
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.logout,
                          title: 'تسجيل الخروج',
                          color: AppColors.error,
                          onTap: () => _showLogoutDialog(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Delete Account
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showDeleteAccountDialog(),
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      label: Text(
                        'حذف الحساب',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 120,
                  ), // Bottom Padding for Floating Navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [context.cardShadow],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(WidgetRef ref) {
    final themeMode = ref.watch(themeProvider).themeMode;
    switch (themeMode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'تلقائي';
    }
  }

  Widget _buildModernMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary.withValues(alpha: 0.7),
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_back_ios,
        size: 16,
        color: context.textSecondary.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    final dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        backgroundColor: dialogContext.surface,
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(color: dialogContext.textPrimary),
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج من حسابك؟',
          style: TextStyle(color: dialogContext.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // عرض مؤشر التحميل
              if (!mounted) return;
              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: Card(
                    color: dialogContext.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LoadingIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تسجيل الخروج...',
                            style: TextStyle(color: dialogContext.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // تسجيل الخروج
                await ref.read(authProvider.notifier).logout();

                if (mounted) {
                  // إغلاق مؤشر التحميل
                  Navigator.pop(dialogContext);

                  // الانتقال إلى صفحة تسجيل الدخول
                  Navigator.of(
                    dialogContext,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  // إغلاق مؤشر التحميل
                  Navigator.pop(dialogContext);

                  // عرض رسالة الخطأ
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('فشل تسجيل الخروج: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        backgroundColor: dialogContext.surface,
        title: Text(
          'حذف الحساب',
          style: TextStyle(color: dialogContext.textPrimary),
        ),
        content: Text(
          'هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(color: dialogContext.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(profileProvider.notifier)
                  .deleteAccount();
              if (success && mounted) {
                // Navigate to login
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
  }
}
