import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Notification Badge Widget
/// يظهر عدد الإشعارات على أي أيقونة أو زر
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double? top;
  final double? right;
  final double? size;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.top,
    this.right,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top ?? -4,
          right: right ?? -4,
          child: Container(
            padding: EdgeInsets.all(size != null ? size! / 4 : 4),
            decoration: BoxDecoration(
              color: badgeColor ?? AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              minWidth: size ?? 20,
              minHeight: size ?? 20,
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: (size ?? 20) / 2,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Notification Dot - نقطة صغيرة للإشعارات
class NotificationDot extends StatelessWidget {
  final Widget child;
  final bool show;
  final Color? color;
  final double? size;
  final double? top;
  final double? right;

  const NotificationDot({
    super.key,
    required this.child,
    this.show = true,
    this.color,
    this.size,
    this.top,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top ?? 0,
          right: right ?? 0,
          child: Container(
            width: size ?? 10,
            height: size ?? 10,
            decoration: BoxDecoration(
              color: color ?? AppColors.error,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated Notification Badge - مع تأثير حركي
class AnimatedNotificationBadge extends StatefulWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double? top;
  final double? right;
  final double? size;

  const AnimatedNotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.top,
    this.right,
    this.size,
  });

  @override
  State<AnimatedNotificationBadge> createState() => _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > _previousCount) {
      _controller.forward(from: 0.0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: widget.top ?? -4,
          right: widget.right ?? -4,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: EdgeInsets.all(widget.size != null ? widget.size! / 4 : 4),
              decoration: BoxDecoration(
                color: widget.badgeColor ?? AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: widget.size ?? 20,
                minHeight: widget.size ?? 20,
              ),
              child: Center(
                child: Text(
                  widget.count > 99 ? '99+' : '${widget.count}',
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontSize: (widget.size ?? 20) / 2,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
