import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class EarningsReportPage extends StatefulWidget {
  const EarningsReportPage({super.key});

  @override
  State<EarningsReportPage> createState() => _EarningsReportPageState();
}

class _EarningsReportPageState extends State<EarningsReportPage> {
  String _selectedPeriod = 'month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الأرباح'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildTotalEarnings(),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsCards(),
            const SizedBox(height: AppSpacing.lg),
            _buildEarningsChart(),
            const SizedBox(height: AppSpacing.lg),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodButton('أسبوع', 'week'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildPeriodButton('شهر', 'month'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildPeriodButton('سنة', 'year'),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGradientStart
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGradientStart
                : AppColors.getTextSecondary(context).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarnings() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        children: [
          const Text(
            'إجمالي الأرباح',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '12,500 ر.س',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 4),
              const Text(
                '+15% من الشهر الماضي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'الحجوزات',
            '45',
            Icons.calendar_today,
            AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            'العمولة',
            '1,250 ر.س',
            Icons.account_balance_wallet,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الأرباح الشهرية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'رسم بياني للأرباح',
                style: TextStyle(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر المعاملات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return _buildTransactionItem();
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_downward,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حجز باقة الزفاف',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '15 نوفمبر 2025',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+2,000 ر.س',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'عمولة: 200 ر.س',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
