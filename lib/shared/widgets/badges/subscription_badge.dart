import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class SubscriptionBadge extends StatelessWidget {
  final String plan; // 'basic', 'pro', 'premium'
  final bool isSmall;

  const SubscriptionBadge({
    super.key,
    required this.plan,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig(plan);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.xs : AppSpacing.sm,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.circular(AppRadius.small),
        boxShadow: [
          BoxShadow(
            color: config.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isSmall ? 12 : 16,
            color: Colors.white,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(String plan) {
    switch (plan.toLowerCase()) {
      case 'premium':
        return _BadgeConfig(
          label: 'Premium',
          icon: Icons.workspace_premium,
          gradient: const LinearGradient(
            colors: [AppColors.gold, Color(0xFFD4AF37)],
          ),
          shadowColor: AppColors.gold.withOpacity(0.3),
        );
      case 'pro':
        return _BadgeConfig(
          label: 'Pro',
          icon: Icons.star,
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
          ),
          shadowColor: AppColors.primaryGradientStart.withOpacity(0.3),
        );
      default:
        return _BadgeConfig(
          label: 'Basic',
          icon: Icons.check_circle,
          gradient: const LinearGradient(
            colors: [Colors.grey, Colors.blueGrey],
          ),
          shadowColor: Colors.grey.withOpacity(0.3),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final Color shadowColor;

  _BadgeConfig({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
  });
}
