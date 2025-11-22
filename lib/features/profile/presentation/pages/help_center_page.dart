import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('مركز المساعدة'),
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
                      Icons.help_outline_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'كيف يمكننا مساعدتك؟',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'ابحث عن إجابات لأسئلتك الشائعة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // FAQ Categories
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأسئلة الشائعة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Booking Questions
                  _buildFAQCategory(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'الحجوزات',
                    questions: [
                      FAQItem(
                        question: 'كيف أحجز مصورة؟',
                        answer:
                            '1. تصفح قائمة المصورات من الصفحة الرئيسية\n'
                            '2. اختر المصورة المناسبة لك\n'
                            '3. اطلع على الباقات المتاحة واختر الباقة المناسبة\n'
                            '4. اختر التاريخ والوقت المناسب\n'
                            '5. أدخل تفاصيل الحجز والموقع\n'
                            '6. أكمل عملية الحجز',
                      ),
                      FAQItem(
                        question: 'كيف ألغي الحجز؟',
                        answer:
                            '• اذهب إلى "حجوزاتي" من القائمة السفلية\n'
                            '• اختر الحجز الذي تريد إلغاءه\n'
                            '• اضغط على زر "إلغاء الحجز"\n'
                            '• أكد عملية الإلغاء\n\n'
                            '⚠️ ملاحظة: قد تطبق سياسة الإلغاء حسب وقت الإلغاء',
                      ),
                      FAQItem(
                        question: 'كيف أعدل موعد الحجز؟',
                        answer:
                            'حالياً لا يمكن تعديل الحجز مباشرة. يمكنك:\n'
                            '1. إلغاء الحجز الحالي\n'
                            '2. إنشاء حجز جديد بالموعد المطلوب\n\n'
                            'أو التواصل مع المصورة مباشرة عبر الدردشة',
                      ),
                      FAQItem(
                        question: 'ماذا يحدث بعد تأكيد الحجز؟',
                        answer:
                            '• ستصلك إشعار بتأكيد الحجز\n'
                            '• ستتلقى المصورة طلب الحجز\n'
                            '• عند قبول المصورة، ستصلك رسالة تأكيد\n'
                            '• يمكنك التواصل مع المصورة عبر الدردشة\n'
                            '• ستصلك تذكيرات قبل موعد الجلسة',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Payment Questions
                  _buildFAQCategory(
                    context,
                    icon: Icons.payment_outlined,
                    title: 'الدفع والأسعار',
                    questions: [
                      FAQItem(
                        question: 'ما هي طرق الدفع المتاحة؟',
                        answer:
                            'نوفر عدة طرق للدفع:\n'
                            '• الدفع عند اللقاء (نقداً)\n'
                            '• التحويل البنكي\n'
                            '• المحافظ الإلكترونية\n\n'
                            'يمكنك الاتفاق مع المصورة على الطريقة المناسبة',
                      ),
                      FAQItem(
                        question: 'هل يمكن استرداد المبلغ؟',
                        answer:
                            'سياسة الاسترداد تعتمد على:\n'
                            '• وقت الإلغاء قبل الموعد\n'
                            '• سياسة المصورة الخاصة\n'
                            '• حالة الحجز\n\n'
                            'للإلغاء قبل 48 ساعة: استرداد كامل\n'
                            'للإلغاء قبل 24 ساعة: استرداد 50%\n'
                            'للإلغاء في نفس اليوم: لا يوجد استرداد',
                      ),
                      FAQItem(
                        question: 'كيف أعرف سعر الباقة؟',
                        answer:
                            'يمكنك معرفة الأسعار من:\n'
                            '• صفحة المصورة - قسم الباقات\n'
                            '• كل باقة تحتوي على تفاصيل السعر والخدمات\n'
                            '• الأسعار شاملة لجميع الخدمات المذكورة',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Account Questions
                  _buildFAQCategory(
                    context,
                    icon: Icons.person_outline,
                    title: 'الحساب والملف الشخصي',
                    questions: [
                      FAQItem(
                        question: 'كيف أعدل معلومات حسابي؟',
                        answer:
                            '1. اذهب إلى "الملف الشخصي"\n'
                            '2. اضغط على "تعديل الملف الشخصي"\n'
                            '3. عدل المعلومات المطلوبة\n'
                            '4. احفظ التغييرات',
                      ),
                      FAQItem(
                        question: 'كيف أغير كلمة المرور؟',
                        answer:
                            '1. اذهب إلى الإعدادات\n'
                            '2. اختر "الأمان"\n'
                            '3. اضغط على "تغيير كلمة المرور"\n'
                            '4. أدخل كلمة المرور الحالية والجديدة\n'
                            '5. احفظ التغييرات',
                      ),
                      FAQItem(
                        question: 'كيف أحذف حسابي؟',
                        answer:
                            '⚠️ تحذير: حذف الحساب نهائي ولا يمكن التراجع عنه\n\n'
                            '1. اذهب إلى الإعدادات\n'
                            '2. انزل إلى "منطقة الخطر"\n'
                            '3. اضغط على "حذف الحساب"\n'
                            '4. أكد عملية الحذف\n\n'
                            'سيتم حذف جميع بياناتك وحجوزاتك',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Reviews Questions
                  _buildFAQCategory(
                    context,
                    icon: Icons.star_outline,
                    title: 'التقييمات والمراجعات',
                    questions: [
                      FAQItem(
                        question: 'كيف أقيّم المصورة؟',
                        answer:
                            'يمكنك تقييم المصورة بعد إكمال الجلسة:\n'
                            '1. اذهب إلى "حجوزاتي"\n'
                            '2. اختر الحجز المكتمل\n'
                            '3. اضغط على "تقييم المصورة"\n'
                            '4. اختر عدد النجوم (1-5)\n'
                            '5. اكتب تعليقك (اختياري)\n'
                            '6. أرسل التقييم',
                      ),
                      FAQItem(
                        question: 'هل يمكن تعديل التقييم؟',
                        answer:
                            'نعم، يمكنك تعديل تقييمك خلال 7 أيام من نشره:\n'
                            '• اذهب إلى صفحة المصورة\n'
                            '• ابحث عن تقييمك\n'
                            '• اضغط على "تعديل"\n'
                            '• عدل التقييم والتعليق\n'
                            '• احفظ التغييرات',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Technical Questions
                  _buildFAQCategory(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'المشاكل التقنية',
                    questions: [
                      FAQItem(
                        question: 'التطبيق لا يعمل بشكل صحيح',
                        answer:
                            'جرب الحلول التالية:\n'
                            '1. أعد تشغيل التطبيق\n'
                            '2. تأكد من اتصالك بالإنترنت\n'
                            '3. حدّث التطبيق لآخر إصدار\n'
                            '4. امسح الكاش من إعدادات الجهاز\n'
                            '5. أعد تثبيت التطبيق\n\n'
                            'إذا استمرت المشكلة، تواصل معنا',
                      ),
                      FAQItem(
                        question: 'لا أستقبل الإشعارات',
                        answer:
                            'تحقق من:\n'
                            '1. إعدادات الإشعارات في التطبيق\n'
                            '2. إعدادات الإشعارات في جهازك\n'
                            '3. تأكد من عدم تفعيل وضع "عدم الإزعاج"\n'
                            '4. تأكد من منح التطبيق صلاحية الإشعارات',
                      ),
                      FAQItem(
                        question: 'الصور لا تظهر',
                        answer:
                            'قد يكون السبب:\n'
                            '• ضعف الاتصال بالإنترنت\n'
                            '• مشكلة في السيرفر (مؤقتة)\n'
                            '• امسح الكاش وأعد المحاولة\n\n'
                            'إذا استمرت المشكلة، تواصل مع الدعم الفني',
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Contact Support Card
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.support_agent_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'لم تجد إجابة لسؤالك؟',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'فريق الدعم الفني جاهز لمساعدتك على مدار الساعة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/contact-us');
                            },
                            icon: const Icon(Icons.phone_outlined, size: 22),
                            label: const Text(
                              'تواصل معنا الآن',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.lg,
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildQuickContactButton(
                              context,
                              icon: Icons.email_outlined,
                              label: 'البريد',
                              onTap: () {
                                Navigator.pushNamed(context, '/contact-us');
                              },
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _buildQuickContactButton(
                              context,
                              icon: Icons.chat_bubble_outline,
                              label: 'واتساب',
                              onTap: () {
                                Navigator.pushNamed(context, '/contact-us');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCategory(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<FAQItem> questions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [context.cardShadow],
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Questions
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 1),
                _buildFAQItem(context, item),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, FAQItem item) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.only(
          right: AppSpacing.md,
          left: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
