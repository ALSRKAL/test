import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hajzy/core/constants/app_spacing.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';
import 'package:hajzy/features/photographer/domain/entities/photographer.dart';
import 'package:hajzy/features/photographer/presentation/pages/fullscreen_video_page.dart';
import 'package:hajzy/shared/widgets/media/image_gallery.dart';
import 'package:hajzy/shared/widgets/media/video_player_widget.dart';

/// صفحة المعرض الكامل الاحترافية
/// تعرض جميع أعمال المصور بتصميم أنيق ومنظم
class FullPortfolioPage extends StatefulWidget {
  final Photographer photographer;
  final int initialIndex;

  const FullPortfolioPage({
    super.key,
    required this.photographer,
    this.initialIndex = 0,
  });

  @override
  State<FullPortfolioPage> createState() => _FullPortfolioPageState();
}

class _FullPortfolioPageState extends State<FullPortfolioPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    final hasVideo = widget.photographer.portfolio.video != null;
    final hasImages = widget.photographer.portfolio.images.isNotEmpty;
    
    int tabCount = 0;
    if (hasImages) tabCount++;
    if (hasVideo) tabCount++;
    
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, tabCount - 1),
    );
    
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 50 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.photographer.portfolio.video != null;
    final hasImages = widget.photographer.portfolio.images.isNotEmpty;
    final images = widget.photographer.portfolio.images;

    return Scaffold(
      backgroundColor: context.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0.5,
        title: Text(
          'معرض ${widget.photographer.name}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: context.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // مشاركة المعرض
            },
          ),
        ],
        bottom: hasVideo && hasImages
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    boxShadow: [context.cardShadow],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text('الصور (${images.length})'),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('الفيديو'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: hasVideo && hasImages
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildImagesSection(images),
                _buildVideoSection(widget.photographer.portfolio.video!),
              ],
            )
          : hasImages
              ? _buildImagesSection(images)
              : _buildVideoSection(widget.photographer.portfolio.video!),
    );
  }

  /// بناء قسم الصور
  Widget _buildImagesSection(List<PortfolioImage> images) {
    if (images.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        message: 'لا توجد صور في المعرض',
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Portfolio Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معرض ${widget.photographer.name}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${images.length} ${images.length == 1 ? 'صورة' : 'صور'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Images Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final image = images[index];
                return _buildImageCard(context, image, images, index);
              },
              childCount: images.length,
            ),
          ),
        ),
        
        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xl),
        ),
      ],
    );
  }

  /// بناء بطاقة الصورة
  Widget _buildImageCard(
    BuildContext context,
    PortfolioImage image,
    List<PortfolioImage> allImages,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageGallery(
              images: allImages.map((img) => img.url).toList(),
              initialIndex: index,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'portfolio_image_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with caching
                  CachedNetworkImage(
                    imageUrl: image.url,
                    fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.background,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.background,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: context.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'فشل تحميل الصورة',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  memCacheWidth: 800,
                  memCacheHeight: 800,
                ),
                
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
                
                // Zoom Icon
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء قسم الفيديو
  Widget _buildVideoSection(PortfolioVideo video) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Info and Fullscreen Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فيديو ${widget.photographer.name}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 18,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'فيديو ترويجي',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Fullscreen Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullscreenVideoPage(
                              videoUrl: video.url,
                              title: 'فيديو ${widget.photographer.name}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.fullscreen,
                        size: 20,
                      ),
                      label: const Text(
                        'ملء الشاشة',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Video Player - يحافظ على أبعاد الفيديو الأصلية
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: VideoPlayerWidget(
                  videoUrl: video.url,
                  autoPlay: false,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Video Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'اضغط على زر "ملء الشاشة" لمشاهدة الفيديو بالوضع الأفقي',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: context.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
