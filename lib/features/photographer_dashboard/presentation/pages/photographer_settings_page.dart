import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';


class PhotographerSettingsPage extends ConsumerStatefulWidget {
  const PhotographerSettingsPage({super.key});

  @override
  ConsumerState<PhotographerSettingsPage> createState() =>
      _PhotographerSettingsPageState();
}

class _PhotographerSettingsPageState
    extends ConsumerState<PhotographerSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load from cache immediately
    final photographer = ref.read(photographersProvider).selectedPhotographer;

    // Load fresh data in background
    if (photographer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(photographersProvider.notifier).getMyPhotographerProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final photographerState = ref.watch(photographersProvider);

    final user = authState.user;
    final photographer = photographerState.selectedPhotographer;

    // No loading screen - show immediately
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/complete-profile');
                  if (mounted) {
                    ref
                        .read(photographersProvider.notifier)
                        .getMyPhotographerProfile();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: photographer?.avatar != null
                          ? NetworkImage(photographer!.avatar!)
                          : null,
                      child: photographer?.avatar == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primaryGradientStart,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      photographer?.name ?? user?.name ?? 'اسم المصورة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.visibility,
                      label: 'المشاهدات',
                      value: '${photographer?.stats.views ?? 0}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.photo_library,
                      label: 'الصور',
                      value: '${photographer?.portfolio.images.length ?? 0}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      label: 'التقييم',
                      value:
                          photographer?.rating.average.toStringAsFixed(1) ??
                          '0.0',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات الحساب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getShadow(context),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _InfoItem(
                          icon: Icons.business_outlined,
                          label: 'معلومات العمل',
                          value:
                              photographer?.bio != null &&
                                  photographer!.bio!.isNotEmpty
                              ? photographer.bio!
                              : 'غير محدد',
                        ),
                        const Divider(),
                        _InfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'الموقع',
                          value: photographer != null
                              ? '${photographer.location.city}, ${photographer.location.area}'
                              : 'غير محدد',
                        ),

                        const Divider(),
                        _InfoItem(
                          icon: Icons.phone_outlined,
                          label: 'رقم الهاتف',
                          value: user?.phone ?? 'غير محدد',
                        ),
                        const Divider(),
                        _InfoItem(
                          icon: Icons.category_outlined,
                          label: 'التخصصات',
                          value:
                              photographer != null &&
                                  photographer.specialties.isNotEmpty
                              ? _getSpecialtiesText(photographer.specialties)
                              : 'غير محدد',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'إعدادات الحساب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileMenuItem(
                    icon: Icons.lock_outline,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تحديث كلمة المرور الخاصة بك',
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'المظهر',
                    subtitle: 'فاتح / داكن',
                    onTap: () {
                      Navigator.pushNamed(context, '/appearance-settings');
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'الاشتراك',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileMenuItem(
                    icon: Icons.card_membership_outlined,
                    title: 'خطة الاشتراك',
                    subtitle: _getSubscriptionText(
                      photographer?.subscription.plan,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'طرق الدفع',
                    subtitle: 'إدارة طرق الدفع',
                    onTap: () {
                      Navigator.pushNamed(context, '/payment-methods');
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'الدعم والمساعدة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'مركز المساعدة',
                    subtitle: 'الأسئلة الشائعة والدعم',
                    onTap: () {
                      Navigator.pushNamed(context, '/help-center');
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.contact_support_outlined,
                    title: 'تواصل معنا',
                    subtitle: 'للاستفسارات والشكاوى',
                    onTap: () {
                      Navigator.pushNamed(context, '/contact-us');
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.policy_outlined,
                    title: 'الشروط والأحكام',
                    subtitle: 'سياسة الخصوصية والاستخدام',
                    onTap: () {
                      _showPrivacyPolicy(context);
                    },
                  ),
                  _ProfileMenuItem(
                    icon: Icons.info_outline,
                    title: 'عن التطبيق',
                    subtitle: 'الإصدار 1.0.0',
                    onTap: () {
                      Navigator.pushNamed(context, '/about-app');
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    title: 'تسجيل الخروج',
                    subtitle: 'الخروج من حسابك',
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubscriptionText(String? plan) {
    switch (plan) {
      case 'pro':
        return 'خطة احترافية';
      case 'premium':
        return 'خطة مميزة';
      case 'basic':
        return 'خطة أساسية';
      default:
        return 'خطة مجانية';
    }
  }

  String _getSpecialtiesText(List<String> specialties) {
    if (specialties.isEmpty) return 'لم يتم التحديد';

    final Map<String, String> specialtiesMap = {
      'weddings': 'أفراح',
      'events': 'مناسبات',
      'portraits': 'بورتريه',
      'children': 'أطفال',
      'products': 'منتجات',
      'fashion': 'أزياء',
      'nature': 'طبيعة',
      'other': 'أخرى',
    };

    final arabicSpecialties = specialties
        .map((s) => specialtiesMap[s] ?? s)
        .take(2)
        .join(', ');

    return specialties.length > 2
        ? '$arabicSpecialties +${specialties.length - 2}'
        : arabicSpecialties;
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
              );
            },
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGradientStart.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.policy_outlined,
                        color: AppColors.primaryGradientStart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'الشروط والأحكام',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPolicySection(
                        'سياسة الخصوصية',
                        'نحن في حجزي نلتزم بحماية خصوصيتك وبياناتك الشخصية. '
                            'نقوم بجمع واستخدام معلوماتك فقط للأغراض المحددة في هذه السياسة.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'جمع البيانات',
                        'نقوم بجمع المعلومات التالية:\n'
                            '• الاسم والبريد الإلكتروني\n'
                            '• رقم الهاتف\n'
                            '• الموقع الجغرافي\n'
                            '• معلومات الحجوزات\n'
                            '• صور الملف الشخصي والمعرض',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'استخدام البيانات',
                        'نستخدم بياناتك لـ:\n'
                            '• تقديم خدماتنا بشكل أفضل\n'
                            '• التواصل معك بخصوص الحجوزات\n'
                            '• تحسين تجربة المستخدم\n'
                            '• إرسال إشعارات مهمة\n'
                            '• الامتثال للمتطلبات القانونية',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'حماية البيانات',
                        'نتخذ إجراءات أمنية صارمة لحماية بياناتك:\n'
                            '• تشفير البيانات\n'
                            '• خوادم آمنة\n'
                            '• وصول محدود للموظفين\n'
                            '• مراقبة مستمرة للأمان',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'حقوقك',
                        'لديك الحق في:\n'
                            '• الوصول إلى بياناتك\n'
                            '• تعديل معلوماتك\n'
                            '• حذف حسابك\n'
                            '• الاعتراض على معالجة البيانات\n'
                            '• نقل بياناتك',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'ملفات تعريف الارتباط',
                        'نستخدم ملفات تعريف الارتباط (Cookies) لتحسين تجربتك. '
                            'يمكنك التحكم في هذه الملفات من إعدادات المتصفح.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'التحديثات',
                        'قد نقوم بتحديث هذه السياسة من وقت لآخر. '
                            'سنقوم بإشعارك بأي تغييرات جوهرية.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPolicySection(
                        'التواصل',
                        'للاستفسارات حول سياسة الخصوصية:\n'
                            'البريد الإلكتروني: privacy@hajzy.com\n'
                            'الهاتف: +967 777 123 456',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGradientStart.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.update,
                              color: AppColors.primaryGradientStart,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'آخر تحديث: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGradientStart, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive
              ? AppColors.error
              : AppColors.primaryGradientStart,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive
                ? AppColors.error
                : AppColors.getTextPrimary(context),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDestructive
                      ? AppColors.error.withValues(alpha: 0.7)
                      : AppColors.getTextSecondary(context),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive
              ? AppColors.error
              : AppColors.getTextSecondary(context),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGradientStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryGradientStart),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
