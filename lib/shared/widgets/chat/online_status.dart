import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';

class OnlineStatus extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineStatus({
    super.key,
    required this.isOnline,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success : AppColors.textSecondaryLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }
}

class OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  final Widget child;

  const OnlineStatusBadge({
    super.key,
    required this.isOnline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          bottom: 0,
          child: OnlineStatus(isOnline: isOnline),
        ),
      ],
    );
  }
}
