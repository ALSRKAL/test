import 'package:flutter/material.dart';
import 'package:hajzy/core/constants/app_colors.dart';

class RatingComponent extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;
  final bool showCount;

  const RatingComponent({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: size, color: AppColors.gold);
          } else if (index < rating) {
            return Icon(Icons.star_half, size: size, color: AppColors.gold);
          } else {
            return Icon(Icons.star_border, size: size, color: AppColors.gold);
          }
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRating extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double size;

  const InteractiveRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 32,
  });

  @override
  State<InteractiveRating> createState() => _InteractiveRatingState();
}

class _InteractiveRatingState extends State<InteractiveRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = (index + 1).toDouble();
            });
            widget.onRatingChanged(_rating);
          },
          child: AnimatedScale(
            scale: index < _rating ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              size: widget.size,
              color: AppColors.gold,
            ),
          ),
        );
      }),
    );
  }
}
