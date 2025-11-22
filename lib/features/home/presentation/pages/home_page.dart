import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajzy/core/constants/app_colors.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/constants/app_strings.dart';
import 'package:hajzy/core/providers/favorites_provider.dart';
import 'package:hajzy/features/photographer/presentation/providers/photographer_provider.dart';
import 'package:hajzy/features/notifications/presentation/providers/notification_provider.dart';
import 'package:hajzy/shared/widgets/errors/empty_state.dart';
import 'package:hajzy/shared/widgets/common/offline_indicator.dart';
import '../widgets/filter_sheet_widget.dart';
import '../widgets/photographer_card_shimmer.dart';
import '../widgets/photographer_card_enhanced.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('═══════════════════════════════════════════════════');
    print('🏠 DEBUG HomePage: initState called');
    print('═══════════════════════════════════════════════════');

    // Load photographers and notifications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🏠 DEBUG HomePage: Loading photographers...');
        ref
            .read(photographersProvider.notifier)
            .getPhotographers(refresh: true);
        // Load notifications count
        ref.read(notificationProvider.notifier).getUnreadCount();
      }
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = ref.read(photographersProvider);
      if (!state.isLoadingMore &&
          state.hasMore &&
          _searchController.text.isEmpty) {
        ref.read(photographersProvider.notifier).getPhotographers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
      context,
    ); // استدعاء super.build للـ AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photographersState = ref.watch(photographersProvider);
    final favoritesList = ref.watch(favoritesProvider);
    final favorites = favoritesList.toSet();

    print('🏠 DEBUG HomePage: build called');
    print('  - isLoading: ${photographersState.isLoading}');
    print(
      '  - photographers count: ${photographersState.photographers.length}',
    );
    print('  - error: ${photographersState.error}');
    print('  - hasMore: ${photographersState.hasMore}');

    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(photographersProvider.notifier)
                    .getPhotographers(refresh: true);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                slivers: [
                  // Modern App Bar with Gradient
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
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
                      child: FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: const EdgeInsets.only(bottom: 16),
                        title: const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                        background: Container(
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
                    ),
                    actions: [
                      _buildNotificationButton(context),
                      const SizedBox(width: 8),
                    ],
                  ),
                  // Modern Search Bar with Enhanced Design
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: TextField(
                            controller: _searchController,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                              height: 1.2,
                            ),
                            cursorColor: AppColors.primaryGradientStart,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن مصورة...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGradientStart
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: AppColors.primaryGradientStart,
                                  size: 22,
                                ),
                              ),
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGradientStart
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.tune,
                                    color: AppColors.primaryGradientStart,
                                    size: 22,
                                  ),
                                  onPressed: () => _showFilterSheet(context),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              _debounce?.cancel();
                              _debounce = Timer(
                                const Duration(milliseconds: 500),
                                () {
                                  if (value.trim().isNotEmpty) {
                                    ref
                                        .read(photographersProvider.notifier)
                                        .searchPhotographers(value.trim());
                                  } else {
                                    ref
                                        .read(photographersProvider.notifier)
                                        .getPhotographers(refresh: true);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                  // Featured Section with Modern Design
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryGradientStart,
                                  AppColors.primaryGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'المصورات المميزة',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Error State
                  if (photographersState.error != null &&
                      photographersState.photographers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                photographersState.error!.contains(
                                      'لا يوجد اتصال',
                                    )
                                    ? 'لا يوجد اتصال بالإنترنت'
                                    : 'حدث خطأ في تحميل البيانات',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                photographersState.error!.contains(
                                      'لا يوجد اتصال',
                                    )
                                    ? 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى'
                                    : photographersState.error!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(photographersProvider.notifier)
                                      .getPhotographers(refresh: true);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Loading State with Shimmer
                  else if (photographersState.isLoading &&
                      photographersState.photographers.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: AppSpacing.lg,
                              mainAxisSpacing: AppSpacing.lg,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const PhotographerCardShimmer(),
                          childCount: 6,
                        ),
                      ),
                    )
                  // Empty State
                  else if (photographersState.photographers.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const EmptyState(
                                message: 'لا توجد مصورات متاحة حالياً',
                                icon: Icons.search_off,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(photographersProvider.notifier)
                                      .getPhotographers(refresh: true);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('تحديث'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  // Photographers Grid
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: AppSpacing.lg,
                              mainAxisSpacing: AppSpacing.lg,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final photographer =
                              photographersState.photographers[index];
                          final isFavorite = favorites.contains(
                            photographer.id,
                          );

                          // Get cover image - use avatar if no portfolio images
                          String coverImage;
                          if (photographer.portfolio.images.isNotEmpty) {
                            coverImage =
                                photographer.portfolio.images.first.url;
                          } else if (photographer.avatar != null &&
                              photographer.avatar!.isNotEmpty) {
                            coverImage = photographer.avatar!;
                          } else {
                            coverImage =
                                ''; // Use empty string to trigger placeholder
                          }

                          // DEBUG: Print price info
                          print('💰 DEBUG Price for ${photographer.name}:');
                          print(
                            '  - startingPrice: ${photographer.startingPrice}',
                          );
                          print(
                            '  - packages count: ${photographer.packages.length}',
                          );

                          // Get currency symbol
                          final currencySymbol = photographer.currency == 'USD'
                              ? '\$'
                              : photographer.currency == 'SAR'
                              ? 'ر.س'
                              : 'ر.ي';

                          // Get price range from packages
                          final prices = photographer.packages
                              .map((p) => p.price)
                              .toList();
                          String priceRange;

                          String formatPrice(num price) {
                            return photographer.currency == 'USD'
                                ? '\u202A${price.toInt()}\$\u202C'
                                : '\u202A${price.toInt()} $currencySymbol\u202C';
                          }

                          if (photographer.startingPrice != null) {
                            priceRange =
                                'تبدأ من ${formatPrice(photographer.startingPrice!)}';
                          } else if (prices.isNotEmpty) {
                            final minPrice = prices.reduce(
                              (a, b) => a < b ? a : b,
                            );
                            final maxPrice = prices.reduce(
                              (a, b) => a > b ? a : b,
                            );
                            priceRange = minPrice == maxPrice
                                ? formatPrice(minPrice)
                                : '${formatPrice(minPrice)} - ${formatPrice(maxPrice)}';
                          } else {
                            priceRange = 'غير محدد';
                          }

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
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/photographer/${photographer.id}',
                              );
                            },
                            onFavorite: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(photographer.id);
                            },
                          );
                        }, childCount: photographersState.photographers.length),
                      ),
                    ),
                  // Loading More Indicator
                  if (photographersState.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  // Bottom Padding for Floating Navbar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (context) => const FilterSheet(),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
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
