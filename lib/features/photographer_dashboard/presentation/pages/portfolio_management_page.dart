import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/photographer/presentation/providers/portfolio_provider.dart';
import 'package:hajzy/features/auth/presentation/providers/auth_provider.dart';
import 'package:hajzy/shared/widgets/loading/loading_indicator.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/widgets/portfolio_stats_card.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/widgets/portfolio_video_section.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/widgets/portfolio_images_section.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/widgets/portfolio_dialogs.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/widgets/portfolio_error_state.dart';
import 'package:hajzy/features/photographer_dashboard/presentation/utils/portfolio_helpers.dart';

class PortfolioManagementPage extends ConsumerStatefulWidget {
  const PortfolioManagementPage({super.key});

  @override
  ConsumerState<PortfolioManagementPage> createState() =>
      _PortfolioManagementPageState();
}

class _PortfolioManagementPageState
    extends ConsumerState<PortfolioManagementPage> {
  final ImagePicker _picker = ImagePicker();
  String? _photographerId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadPortfolio());
  }

  Future<void> _loadPortfolio() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      
      if (user == null) {
        if (mounted) {
          PortfolioHelpers.showErrorSnackBar(context, 'الرجاء تسجيل الدخول أولاً');
          Navigator.of(context).pop();
        }
        return;
      }

      if (user.role != 'photographer') {
        if (mounted) {
          PortfolioHelpers.showErrorSnackBar(
            context,
            'هذه الصفحة متاحة للمصورين فقط. الرجاء إكمال ملفك الشخصي أولاً.',
          );
          Navigator.of(context).pop();
        }
        return;
      }

      await ref.read(portfolioProvider.notifier).loadMyProfile();
      
      final portfolioState = ref.read(portfolioProvider);
      _photographerId = portfolioState.photographerId;
      
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      if (mounted) {
        PortfolioHelpers.showErrorSnackBar(context, 'فشل تحميل المعرض: ${e.toString()}');
        setState(() {
          _photographerId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(portfolioProvider);

    // Listen to errors
    ref.listen<PortfolioState>(portfolioProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            PortfolioHelpers.showErrorSnackBar(context, next.error!);
            ref.read(portfolioProvider.notifier).clearError();
          }
        });
      }
    });

    // Show loading state
    if (portfolioState.isLoading && portfolioState.images.isEmpty && _photographerId == null) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && portfolioState.isLoading && _photographerId == null) {
          PortfolioHelpers.showErrorSnackBar(
            context,
            'انتهت مهلة التحميل. الرجاء المحاولة مرة أخرى.',
          );
          Navigator.of(context).pop();
        }
      });
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المعرض'),
          elevation: 0,
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }

    // Show error state if photographer not found
    if (_photographerId == null && !portfolioState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المعرض'),
          elevation: 0,
        ),
        body: PortfolioErrorState(
          onRetry: _loadPortfolio,
          onCompleteProfile: () {
            Navigator.of(context).pushReplacementNamed('/complete-profile');
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.background,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_photographerId != null) {
            await ref.read(portfolioProvider.notifier).loadPortfolio(_photographerId!);
          }
        },
        color: AppColors.primaryGradientStart,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PortfolioStatsCard(
                imageCount: portfolioState.imageCount,
                hasVideo: portfolioState.video != null,
              ),
              const SizedBox(height: AppSpacing.lg),
              PortfolioVideoSection(
                video: portfolioState.video,
                portfolioState: portfolioState,
                onUpload: _pickVideo,
                onDelete: _deleteVideo,
              ),
              const SizedBox(height: AppSpacing.xl),
              PortfolioImagesSection(
                images: portfolioState.images,
                imageCount: portfolioState.imageCount,
                portfolioState: portfolioState,
                onAddImages: _pickImages,
                onDeleteImage: _deleteImage,
                onImageTap: (image, index) => PortfolioDialogs.showImagePreview(
                  context,
                  image,
                  index,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGradientStart.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'إدارة المعرض',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.tips_and_updates_outlined),
                onPressed: () => PortfolioDialogs.showPortfolioTips(context),
                tooltip: 'نصائح المعرض',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final file = await PortfolioHelpers.pickVideo(_picker);
    
    if (file == null) {
      if (mounted) {
        PortfolioHelpers.showErrorSnackBar(context, 'حجم الفيديو يتجاوز 100MB');
      }
      return;
    }

    final success = await ref.read(portfolioProvider.notifier).uploadVideo(file);

    if (success && mounted) {
      PortfolioHelpers.showSuccessSnackBar(context, 'تم رفع الفيديو بنجاح ✓');
    }
  }

  Future<void> _deleteVideo(String publicId) async {
    final confirm = await PortfolioDialogs.showDeleteConfirmation(context, 'الفيديو');
    if (confirm != true) return;

    final success = await ref.read(portfolioProvider.notifier).deleteVideo(publicId);
    
    if (success && mounted) {
      PortfolioHelpers.showSuccessSnackBar(context, 'تم حذف الفيديو بنجاح ✓');
    }
  }

  Future<void> _pickImages() async {
    final files = await PortfolioHelpers.pickImages(_picker);
    
    if (files == null || files.isEmpty) return;

    final portfolioState = ref.read(portfolioProvider);
    final currentCount = portfolioState.imageCount;

    if (!PortfolioHelpers.validateImageCount(currentCount, files.length, 20)) {
      if (mounted) {
        final remaining = PortfolioHelpers.getRemainingSlots(currentCount, 20);
        PortfolioHelpers.showErrorSnackBar(
          context,
          'يمكنك إضافة $remaining صورة فقط (الحد الأقصى 20)',
        );
      }
      return;
    }

    final success = await ref.read(portfolioProvider.notifier).uploadImages(files);

    if (success && mounted) {
      PortfolioHelpers.showSuccessSnackBar(
        context,
        'تم رفع ${files.length} صورة بنجاح ✓',
      );
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final confirm = await PortfolioDialogs.showDeleteConfirmation(context, 'الصورة');
    if (confirm != true) return;

    final success = await ref.read(portfolioProvider.notifier).deleteImage(imageId);
    
    if (success && mounted) {
      PortfolioHelpers.showSuccessSnackBar(context, 'تم حذف الصورة بنجاح ✓');
    }
  }
}
