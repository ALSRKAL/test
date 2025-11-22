import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Gradient? gradient;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isLoading ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: isOutlined ? null : (gradient ?? AppColors.primaryGradient),
          border: isOutlined ? Border.all(color: AppColors.primaryGradientStart, width: 2) : null,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryGradientStart.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isOutlined ? AppColors.primaryGradientStart : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
