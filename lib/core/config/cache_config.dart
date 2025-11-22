import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// تكوين الـ cache للصور - يعمل أوف لاين تلقائياً
class CacheConfig {
  static const String key = 'hajzyImageCache';
  static const Duration maxAge = Duration(days: 30); // زيادة المدة للأوف لاين
  static const int maxNrOfCacheObjects = 500; // زيادة العدد

  static CacheManager get instance => CacheManager(
        Config(
          key,
          stalePeriod: maxAge,
          maxNrOfCacheObjects: maxNrOfCacheObjects,
        ),
      );
}
