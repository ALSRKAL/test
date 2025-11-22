import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/services/media/image_service.dart';
import 'package:hajzy/shared/widgets/buttons/custom_button.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';

class VerificationRequestScreen extends ConsumerStatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  ConsumerState<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState
    extends ConsumerState<VerificationRequestScreen> {
  File? _idCardImage;
  List<File> _portfolioImages = [];
  bool _isSubmitting = false;
  final ImageService _imageService = ImageService();

  Future<void> _pickIdCard() async {
    final file = await _imageService.pickImageFromGallery();
    if (file != null) {
      setState(() {
        _idCardImage = file;
      });
    }
  }

  Future<void> _pickPortfolioImages() async {
    final files = await _imageService.pickMultipleImages(
      maxImages: 10 - _portfolioImages.length,
    );
    if (files.isNotEmpty) {
      setState(() {
        _portfolioImages.addAll(files);
      });
    }
  }

  Future<void> _submit() async {
    if (_idCardImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إرفاق صورة الهوية')));
      return;
    }

    // Portfolio images are now optional
    // if (_portfolioImages.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('الرجاء إرفاق نماذج من أعمالك')),
    //   );
    //   return;
    // }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Upload ID Card
      // We use the repository directly for uploads as the provider doesn't expose upload methods directly usually
      // But we can access the repository from the usecase in the provider
      final repository = ref.read(photographerRepositoryProvider);

      final idCardUrls = await repository.uploadImages([_idCardImage!.path]);
      if (idCardUrls.isEmpty) throw Exception('Failed to upload ID Card');
      final idCardUrl = idCardUrls.first;

      // 2. Upload Portfolio Images (Optional)
      List<String> portfolioUrls = [];
      if (_portfolioImages.isNotEmpty) {
        portfolioUrls = await repository.uploadImages(
          _portfolioImages.map((f) => f.path).toList(),
        );
      }

      // 3. Submit Verification
      await ref
          .read(photographersProvider.notifier)
          .submitVerification(
            idCardUrl: idCardUrl,
            portfolioSamples: portfolioUrls,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب التوثيق بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب التوثيق')),
      body: _isSubmitting
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('الهوية الشخصية'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildIdCardUpload(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('نماذج الأعمال (اختياري)'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPortfolioUpload(),
                  const SizedBox(height: AppSpacing.xl),
                  CustomButton(
                    text: 'إرسال الطلب',
                    onPressed: _submit,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'للحصول على شارة التوثيق، يرجى إرفاق صورة من الهوية الشخصية ونماذج من أعمالك السابقة للمراجعة.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIdCardUpload() {
    return GestureDetector(
      onTap: _pickIdCard,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: _idCardImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Image.file(_idCardImage!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اضغط لإرفاق صورة الهوية',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPortfolioUpload() {
    return Column(
      children: [
        if (_portfolioImages.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _portfolioImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _portfolioImages.length) {
                return _buildAddButton();
              }
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _portfolioImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _portfolioImages.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          GestureDetector(
            onTap: _pickPortfolioImages,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'اضغط لإرفاق صور الأعمال',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickPortfolioImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.add, color: Colors.grey),
      ),
    );
  }
}
