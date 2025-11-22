import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/core/providers/favorites_provider.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/booking/presentation/pages/booking_page.dart';
import 'package:hajzy/features/chat/presentation/pages/chat_page.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/features/photographer/presentation/widgets/photographer_header.dart';
import 'package:hajzy/features/photographer/presentation/widgets/photographer_info_section.dart';
import 'package:hajzy/features/photographer/presentation/widgets/photographer_portfolio_section.dart';
import 'package:hajzy/features/photographer/presentation/widgets/photographer_packages_section.dart';
import 'package:hajzy/features/photographer/presentation/widgets/photographer_reviews_section_enhanced.dart';
import 'package:hajzy/features/photographer/presentation/widgets/photographer_details_shimmer.dart';

import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;

class PhotographerDetailsPage extends ConsumerStatefulWidget {
  final String photographerId;

  const PhotographerDetailsPage({super.key, required this.photographerId});

  @override
  ConsumerState<PhotographerDetailsPage> createState() =>
      _PhotographerDetailsPageState();
}

class _PhotographerDetailsPageState
    extends ConsumerState<PhotographerDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // استخدام الـ cache إذا كانت البيانات موجودة
      ref
          .read(photographersProvider.notifier)
          .getPhotographerDetails(widget.photographerId, forceRefresh: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photographersProvider);
    final isFavorite = ref
        .watch(favoritesProvider)
        .contains(widget.photographerId);

    // عرض shimmer أثناء التحميل بدلاً من البيانات القديمة
    if (state.isLoading &&
        (state.selectedPhotographer == null ||
            state.selectedPhotographer!.id != widget.photographerId)) {
      return const PhotographerDetailsShimmer();
    }

    if (state.error != null && state.selectedPhotographer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المصورة')),
        body: custom.CustomErrorWidget(
          message: state.error!,
          onRetry: () => ref
              .read(photographersProvider.notifier)
              .getPhotographerDetails(widget.photographerId),
        ),
      );
    }

    final photographer = state.selectedPhotographer;
    if (photographer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المصورة')),
        body: const custom.CustomErrorWidget(message: 'المصورة غير موجودة'),
      );
    }

    final coverImage = photographer.portfolio.images.isNotEmpty
        ? photographer.portfolio.images.first.url
        : 'https://via.placeholder.com/400x300';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(photographersProvider.notifier)
              .getPhotographerDetails(
                widget.photographerId,
                forceRefresh: true,
              );
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, coverImage, isFavorite),
            SliverToBoxAdapter(
              child: Container(
                color: context.background,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with theme background
                    Container(
                      color: context.surface,
                      child: PhotographerHeader(photographer: photographer),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Info section
                    Container(
                      color: context.surface,
                      child: PhotographerInfoSection(
                        photographer: photographer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),



                    // Portfolio section
                    Container(
                      color: context.surface,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: PhotographerPortfolioSection(
                        photographer: photographer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Packages section
                    Container(
                      color: context.surface,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: PhotographerPackagesSection(
                        photographer: photographer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Reviews section (enhanced)
                    PhotographerReviewsSectionEnhanced(
                      photographer: photographer,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, photographer),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    String coverImage,
    bool isFavorite,
  ) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      stretch: true,
      backgroundColor: context.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              coverImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryGradientStart,
                        AppColors.primaryGradientEnd,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 100,
                    color: Colors.white54,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFavorite
                ? AppColors.error.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              ref
                  .read(favoritesProvider.notifier)
                  .toggle(widget.photographerId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, photographer) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: [context.cardShadow],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat button
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primaryGradientStart,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: IconButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: '',
                        otherUserId: photographer.userId,
                        otherUserName: photographer.name,
                        otherUserAvatar: photographer.avatar,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryGradientStart,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Book button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGradientStart.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookingPage(photographerId: widget.photographerId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: const Text(
                    AppStrings.bookNow,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
