import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'free';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('خطط الاشتراك'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'اختر الخطة المناسبة لك',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'جميع الخطط تشمل ضمان استرداد المال خلال 30 يوم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Current Plan Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'خطتك الحالية: مجانية',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Subscription Plans
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  _buildPlanCard(
                    plan: 'free',
                    title: 'مجانية',
                    price: '0',
                    period: 'مجاناً للأبد',
                    features: [
                      'حتى 5 صور في المعرض',
                      'فيديو تعريفي واحد',
                      'حجوزات غير محدودة',
                      'دعم فني أساسي',
                      'ظهور في نتائج البحث',
                    ],
                    color: Colors.grey,
                    isCurrent: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPlanCard(
                    plan: 'basic',
                    title: 'أساسية',
                    price: '2,000',
                    period: 'شهرياً',
                    features: [
                      'حتى 15 صورة في المعرض',
                      'فيديو تعريفي واحد',
                      'حجوزات غير محدودة',
                      'دعم فني ذو أولوية',
                      'ظهور مميز في البحث',
                      'إحصائيات متقدمة',
                      'شارة "مصورة معتمدة"',
                    ],
                    color: Colors.blue,
                    isPopular: false,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPlanCard(
                    plan: 'pro',
                    title: 'احترافية',
                    price: '4,000',
                    period: 'شهرياً',
                    features: [
                      'صور غير محدودة',
                      'فيديوهات متعددة',
                      'حجوزات غير محدودة',
                      'دعم فني VIP على مدار الساعة',
                      'ظهور في الصفحة الرئيسية',
                      'إحصائيات وتحليلات متقدمة',
                      'شارة "مصورة محترفة"',
                      'خصم 10% على رسوم المنصة',
                      'أدوات تسويق متقدمة',
                    ],
                    color: Colors.purple,
                    isPopular: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPlanCard(
                    plan: 'premium',
                    title: 'مميزة',
                    price: '7,000',
                    period: 'شهرياً',
                    features: [
                      'جميع مميزات الخطة الاحترافية',
                      'مدير حساب شخصي',
                      'ظهور دائم في أعلى النتائج',
                      'حملات إعلانية مجانية',
                      'شارة "مصورة مميزة"',
                      'خصم 20% على رسوم المنصة',
                      'تدريب وورش عمل مجانية',
                      'أولوية في الحجوزات',
                      'تقارير شهرية مفصلة',
                    ],
                    color: Colors.amber,
                    isPopular: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [context.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        const Text(
                          'أسئلة شائعة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildFAQItem(
                      'هل يمكنني تغيير الخطة لاحقاً؟',
                      'نعم، يمكنك الترقية أو التخفيض في أي وقت',
                    ),
                    _buildFAQItem(
                      'هل يمكنني إلغاء الاشتراك؟',
                      'نعم، يمكنك الإلغاء في أي وقت دون رسوم إضافية',
                    ),
                    _buildFAQItem(
                      'ماذا يحدث عند انتهاء الاشتراك؟',
                      'سيتم تحويلك تلقائياً للخطة المجانية',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String plan,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    bool isPopular = false,
    bool isCurrent = false,
  }) {
    final isSelected = _selectedPlan == plan;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isPopular
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          if (isPopular || isSelected)
            BoxShadow(
              color: (isSelected ? AppColors.primary : color)
                  .withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        children: [
          // Popular Badge
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'الأكثر شعبية',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Plan Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getPlanIcon(plan),
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'الحالية',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'ريال',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Features
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: AppSpacing.xl),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent
                        ? null
                        : () {
                            setState(() => _selectedPlan = plan);
                            _showSubscribeDialog(plan, title, price);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey : color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCurrent ? 0 : 4,
                    ),
                    child: Text(
                      isCurrent ? 'الخطة الحالية' : 'اشترك الآن',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPlanIcon(String plan) {
    switch (plan) {
      case 'free':
        return Icons.card_giftcard;
      case 'basic':
        return Icons.star_border;
      case 'pro':
        return Icons.star_half;
      case 'premium':
        return Icons.star;
      default:
        return Icons.card_membership;
    }
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog(String plan, String title, String price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('تأكيد الاشتراك'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد الاشتراك في الخطة $title؟'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المبلغ الإجمالي:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$price ريال/شهرياً',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
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
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payment-methods',
                  arguments: {'plan': plan, 'price': price});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('متابعة للدفع'),
          ),
        ],
      ),
    );
  }
}
