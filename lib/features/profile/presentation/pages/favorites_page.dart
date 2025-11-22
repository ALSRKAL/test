import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../photographer/presentation/providers/photographer_provider.dart';
import '../../../photographer/data/datasources/photographer_local_datasource.dart';
import '../../../../core/services/offline_service.dart';
import '../../../home/presentation/widgets/photographer_card_enhanced.dart';
import '../../../home/presentation/widgets/photographer_card_shimmer.dart';
import '../../../../shared/widgets/errors/empty_state.dart';
import '../../../../shared/widgets/common/offline_indicator.dart';
import '../../../photographer/data/models/photographer_model.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  List<PhotographerModel> _favoritePhotographers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritePhotographers();
  }

  Future<void> _loadFavoritePhotographers() async {
    setState(() => _isLoading = true);

    try {
      // تحميل قائمة المفضلة من الكاش أولاً (سريع)
      final localDataSource = PhotographerLocalDataSource(OfflineService());
      final localFavorites = await localDataSource.getFavorites();

      // عرض البيانات من الكاش فوراً
      if (localFavorites.isNotEmpty) {
        final cachedPhotographers = <PhotographerModel>[];
        for (final p in localFavorites) {
          try {
            cachedPhotographers.add(PhotographerModel.fromJson(p));
          } catch (e) {
            print('Error parsing cached favorite: $e');
          }
        }

        if (cachedPhotographers.isNotEmpty) {
          setState(() {
            _favoritePhotographers = cachedPhotographers;
            _isLoading = false;
          });
        }
      }

      // تحديث من السيرفر في الخلفية
      await ref.read(favoritesProvider.notifier).refresh();
      final favoriteIds = ref.read(favoritesProvider);

      if (favoriteIds.isEmpty) {
        setState(() {
          _favoritePhotographers = [];
          _isLoading = false;
        });
        return;
      }

      // تحميل البيانات الكاملة من السيرفر
      final photographers = <PhotographerModel>[];
      for (final id in favoriteIds) {
        try {
          final photographer = await ref
              .read(photographersProvider.notifier)
              .getPhotographerById(id);
          if (photographer != null) {
            photographers.add(
              PhotographerModel(
                id: photographer.id,
                userId: photographer.userId,
                name: photographer.name,
                email: photographer.email,
                avatar: photographer.avatar,
                bio: photographer.bio,
                specialties: photographer.specialties,
                location: photographer.location,
                portfolio: photographer.portfolio,
                packages: photographer.packages,
                rating: photographer.rating,
                subscription: photographer.subscription,
                featured: photographer.featured,
                verification: photographer.verification,
                availability: photographer.availability,
                isVerified: photographer.isVerified,
                stats: photographer.stats,
              ),
            );
          }
        } catch (e) {
          print('Error loading photographer $id: $e');
        }
      }

      if (mounted) {
        setState(() {
          _favoritePhotographers = photographers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteIds = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('المفضلة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.primaryGradientStart,
                AppColors.primaryGradientEnd,
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : favoriteIds.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadFavoritePhotographers,
                    child: _favoritePhotographers.isEmpty
                        ? _buildEmptyState()
                        : _buildFavoritesList(
                            _favoritePhotographers,
                            favoriteIds.toSet(),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyState(
        message: 'لا توجد مصورات في المفضلة',
        icon: Icons.favorite_border,
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const PhotographerCardShimmer(),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList(
    List<dynamic> photographers,
    Set<String> favorites,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final photographer = photographers[index];
              return _buildPhotographerCard(photographer, favorites);
            }, childCount: photographers.length),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotographerCard(dynamic photographer, Set<String> favorites) {
    final isFavorite = favorites.contains(photographer.id);
    final coverImage = _getCoverImage(photographer);
    final priceRange = _getPriceRange(photographer);

    return PhotographerCardEnhanced(
      id: photographer.id,
      name: photographer.name,
      specialties: photographer.specialties,
      coverImageUrl: coverImage,
      avatarUrl: photographer.avatar,
      rating: photographer.rating.average,
      reviewCount: photographer.rating.count,
      location: photographer.location.city,
      priceRange: priceRange,
      isFeatured: photographer.featured.isActive,
      isFavorite: isFavorite,
      isVerified: photographer.isVerified,
      viewCount: photographer.stats.views,
      subscriptionPlan: photographer.subscription.plan,
      onTap: () => _navigateToPhotographer(photographer.id),
      onFavorite: () => _toggleFavorite(photographer.id),
    );
  }

  String _getCoverImage(dynamic photographer) {
    if (photographer.portfolio.images.isNotEmpty) {
      return photographer.portfolio.images.first.url;
    }
    if (photographer.avatar != null && photographer.avatar!.isNotEmpty) {
      return photographer.avatar!;
    }
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }

  String _getPriceRange(dynamic photographer) {
    final currencySymbol = photographer.currency == 'USD'
        ? '\$'
        : photographer.currency == 'SAR'
        ? 'ر.س'
        : 'ر.ي';

    String formatPrice(num price) {
      return photographer.currency == 'USD'
          ? '\u202A${price.toInt()}\$\u202C'
          : '\u202A${price.toInt()} $currencySymbol\u202C';
    }

    if (photographer.startingPrice != null) {
      return 'تبدأ من ${formatPrice(photographer.startingPrice!)}';
    }

    final prices = photographer.packages.map((p) => p.price).toList();

    if (prices.isEmpty) return 'غير محدد';

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return minPrice == maxPrice
        ? formatPrice(minPrice)
        : '${formatPrice(minPrice)} - ${formatPrice(maxPrice)}';
  }

  void _navigateToPhotographer(String photographerId) {
    Navigator.pushNamed(context, '/photographer/$photographerId');
  }

  void _toggleFavorite(String photographerId) {
    ref.read(favoritesProvider.notifier).toggle(photographerId);
  }
}
