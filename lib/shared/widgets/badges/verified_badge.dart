import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showLabel;

  const VerifiedBadge({
    super.key,
    this.size = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 4),
          Text(
            'موثق',
            style: TextStyle(
              color: AppColors.success,
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    
    return _buildIcon();
  }

  Widget _buildIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * 0.7,
      ),
    );
  }
}
