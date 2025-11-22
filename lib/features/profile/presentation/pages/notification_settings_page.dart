import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  late bool _messagesEnabled;
  late bool _bookingsEnabled;
  late bool _reviewsEnabled;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(profileProvider).profile?.notificationSettings;
    _messagesEnabled = settings?.messages ?? true;
    _bookingsEnabled = settings?.bookings ?? true;
    _reviewsEnabled = settings?.reviews ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (profileState.isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Info Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'يمكنك التحكم في الإشعارات التي تريد استقبالها',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Settings Card
          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [context.cardShadow],
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.message_outlined,
                  title: 'إشعارات الرسائل',
                  subtitle: 'استقبال إشعارات عند وصول رسائل جديدة',
                  value: _messagesEnabled,
                  onChanged: (value) {
                    setState(() => _messagesEnabled = value);
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: context.dividerColor),
                _buildSettingTile(
                  icon: Icons.book_outlined,
                  title: 'إشعارات الحجوزات',
                  subtitle: 'استقبال إشعارات عند تحديث حالة الحجوزات',
                  value: _bookingsEnabled,
                  onChanged: (value) {
                    setState(() => _bookingsEnabled = value);
                    _saveSettings();
                  },
                ),
                Divider(height: 1, color: context.dividerColor),
                _buildSettingTile(
                  icon: Icons.star_outline,
                  title: 'إشعارات التقييمات',
                  subtitle: 'استقبال إشعارات عند إضافة تقييمات جديدة',
                  value: _reviewsEnabled,
                  onChanged: (value) {
                    setState(() => _reviewsEnabled = value);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),

          if (profileState.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      profileState.error!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }

  Future<void> _saveSettings() async {
    final settings = NotificationSettings(
      messages: _messagesEnabled,
      bookings: _bookingsEnabled,
      reviews: _reviewsEnabled,
    );

    final success = await ref
        .read(profileProvider.notifier)
        .updateNotificationSettings(settings);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
