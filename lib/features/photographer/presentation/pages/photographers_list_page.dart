import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/shared/widgets/cards/photographer_card.dart';
import 'package:hajzy/shared/widgets/errors/empty_state.dart';
import 'package:hajzy/shared/widgets/errors/error_widget.dart' as custom;
import 'package:hajzy/shared/widgets/loading/shimmer_widget.dart';

class PhotographersListPage extends ConsumerStatefulWidget {
  final String? category;
  final String? city;

  const PhotographersListPage({super.key, this.category, this.city});

  @override
  ConsumerState<PhotographersListPage> createState() =>
      _PhotographersListPageState();
}

class _PhotographersListPageState extends ConsumerState<PhotographersListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(photographersProvider.notifier).getPhotographers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photographersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category ?? AppStrings.photographers)),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(photographersProvider.notifier).getPhotographers();
        },
        child: state.isLoading && state.photographers.isEmpty
            ? _buildShimmerLoading()
            : state.error != null && state.photographers.isEmpty
            ? custom.CustomErrorWidget(
                message: state.error!,
                onRetry: () {
                  ref.read(photographersProvider.notifier).getPhotographers();
                },
              )
            : state.photographers.isEmpty
            ? const EmptyState(
                icon: Icons.search_off,
                message: 'لا توجد مصورات',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.photographers.length,
                itemBuilder: (context, index) {
                  final photographer = state.photographers[index];
                  final coverImage = photographer.portfolio.images.isNotEmpty
                      ? photographer.portfolio.images.first.url
                      : 'https://via.placeholder.com/400x300';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PhotographerCard(
                      name: photographer.name,
                      specialty: photographer.specialties.isNotEmpty
                          ? photographer.specialties.first
                          : 'مصورة',
                      imageUrl: coverImage,
                      rating: photographer.rating.average,
                      reviewCount: photographer.rating.count,
                      priceRange: photographer.startingPrice != null
                          ? 'تبدأ من \u202A${photographer.startingPrice!.toInt()}${photographer.currency == 'USD' ? '\$' : ' ${photographer.currency == 'SAR' ? 'ر.س' : 'ر.ي'}'}\u202C'
                          : photographer.packages.isNotEmpty
                          ? '\u202A${photographer.packages.first.price.toStringAsFixed(0)}${photographer.currency == 'USD' ? '\$' : ' ${photographer.currency == 'SAR' ? 'ر.س' : 'ر.ي'}'}\u202C'
                          : 'غير محدد',
                      isFeatured: photographer.featured.isActive,
                      isVerified: photographer.isVerified,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/photographer/${photographer.id}',
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ShimmerWidget(width: double.infinity, height: 280),
        );
      },
    );
  }
}
