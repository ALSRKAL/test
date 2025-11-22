import 'package:flutter/material.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';

class PhotographerCardShimmer extends StatefulWidget {
  const PhotographerCardShimmer({super.key});

  @override
  State<PhotographerCardShimmer> createState() => _PhotographerCardShimmerState();
}

class _PhotographerCardShimmerState extends State<PhotographerCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final shimmerBaseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final shimmerHighlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [context.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(shimmerBaseColor, shimmerHighlightColor),
              Expanded(child: _buildContentSection(shimmerBaseColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection(Color baseColor, Color highlightColor) {
    return Stack(
      children: [
        // الصورة الرئيسية shimmer
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  baseColor,
                  highlightColor,
                  baseColor,
                ],
                stops: [
                  0.0,
                  _animation.value.clamp(0.0, 1.0),
                  1.0,
                ],
              ),
            ),
          ),
        ),

        // شارة مميزة shimmer
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 50,
              height: 16,
            ),
          ),
        ),

        // زر المفضلة shimmer
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 18,
              height: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(Color baseColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // الاسم shimmer
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 15,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // التخصص shimmer
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),

          // التقييم والموقع shimmer
          Row(
            children: [
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 11,
                width: 50,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // السعر shimmer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              height: 12,
              width: 70,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
