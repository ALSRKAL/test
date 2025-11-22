import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/review/presentation/providers/review_provider.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';

class CreateReviewPage extends ConsumerStatefulWidget {
  final String photographerId;
  final String photographerName;
  final String bookingId;

  const CreateReviewPage({
    super.key,
    required this.photographerId,
    required this.photographerName,
    required this.bookingId,
  });

  @override
  ConsumerState<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends ConsumerState<CreateReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم المصورة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photographer Info
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: context.dividerColor),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryGradientStart,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تقييم',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.photographerName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Rating Section
              Text(
                'التقييم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  children: [
                    Text(
                      _rating.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGradientStart,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              size: 40,
                              color: AppColors.gold,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _getRatingText(_rating),
                      style: TextStyle(
                        fontSize: 16,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Comment Section
              Text(
                'التعليق',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'شاركنا تجربتك مع هذه المصورة...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء كتابة تعليق';
                  }
                  if (value.trim().length < 5) {
                    return 'التعليق يجب أن يكون 5 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Submit Button
              CustomButton(
                text: 'إرسال التقييم',
                onPressed: _isSubmitting ? null : _submitReview,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'مقبول';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(reviewProvider.notifier).createReview(
            photographerId: widget.photographerId,
            bookingId: widget.bookingId,
            rating: _rating,
            comment: _commentController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال التقييم بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال التقييم: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
