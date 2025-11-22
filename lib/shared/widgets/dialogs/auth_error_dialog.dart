import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/errors/auth_error_type.dart';

/// مربع حوار احترافي لعرض أخطاء المصادقة
class AuthErrorDialog extends StatelessWidget {
  final AuthErrorInfo errorInfo;
  final VoidCallback? onActionPressed;

  const AuthErrorDialog({
    super.key,
    required this.errorInfo,
    this.onActionPressed,
  });

  /// عرض مربع الحوار
  static Future<bool?> show(
    BuildContext context,
    AuthErrorInfo errorInfo, {
    VoidCallback? onActionPressed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthErrorDialog(
        errorInfo: errorInfo,
        onActionPressed: onActionPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة الخطأ
            _buildErrorIcon(),
            const SizedBox(height: AppSpacing.lg),

            // عنوان الخطأ
            Text(
              errorInfo.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // رسالة الخطأ
            Text(
              errorInfo.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // الأزرار
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// بناء أيقونة الخطأ حسب النوع
  Widget _buildErrorIcon() {
    IconData icon;
    Color color;

    switch (errorInfo.type) {
      case AuthErrorType.noInternet:
      case AuthErrorType.poorConnection:
        icon = Icons.wifi_off_rounded;
        color = Colors.orange;
        break;

      case AuthErrorType.serverError:
        icon = Icons.construction_rounded;
        color = Colors.amber;
        break;

      case AuthErrorType.userAlreadyExists:
        icon = Icons.person_add_disabled_rounded;
        color = Colors.blue;
        break;

      case AuthErrorType.userNotFound:
        icon = Icons.person_search_rounded;
        color = Colors.blue;
        break;

      case AuthErrorType.wrongPassword:
        icon = Icons.lock_reset_rounded;
        color = Colors.orange;
        break;

      case AuthErrorType.accountBlocked:
        icon = Icons.block_rounded;
        color = Colors.red;
        break;

      case AuthErrorType.timeout:
        icon = Icons.timer_off_rounded;
        color = Colors.orange;
        break;

      default:
        icon = Icons.error_outline_rounded;
        color = Colors.red;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  /// بناء الأزرار
  Widget _buildActions(BuildContext context) {
    // إذا كان هناك إجراء إضافي
    if (errorInfo.actionText != null) {
      return Column(
        children: [
          // زر الإجراء الرئيسي
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onActionPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.primaryGradientStart,
              ),
              child: Text(
                errorInfo.actionText!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // زر الإغلاق
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'إغلاق',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // زر واحد فقط للإغلاق
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(false),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primaryGradientStart,
        ),
        child: const Text(
          'حسناً',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
