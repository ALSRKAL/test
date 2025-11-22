import '../../domain/entities/photographer.dart';

class PhotographerModel extends Photographer {
  PhotographerModel({
    required super.id,
    required super.userId,
    required super.name,
    super.email,
    super.avatar,
    super.bio,
    required super.specialties,
    required super.location,
    required super.portfolio,
    required super.packages,
    required super.rating,
    required super.subscription,
    required super.featured,
    required super.verification,
    required super.availability,
    super.isVerified,
    required super.stats,
    super.startingPrice,
    super.currency,
  });

  factory PhotographerModel.fromJson(dynamic json) {
    return PhotographerModel(
      id: json['_id'] ?? json['id'],
      userId: json['user']?['_id'] ?? json['user'] ?? '',
      name: json['user']?['name'] ?? json['name'] ?? '',
      email: json['user']?['email'],
      avatar: json['user']?['avatar'],
      bio: json['bio'],
      specialties: List<String>.from(json['specialties'] ?? []),
      location: LocationModel.fromJson(json['location'] ?? {}),
      portfolio: PortfolioModel.fromJson(json['portfolio'] ?? {}),
      packages:
          (json['packages'] as List?)
              ?.map((p) => PackageModel.fromJson(p))
              .toList() ??
          [],
      rating: RatingModel.fromJson(json['rating'] ?? {}),
      subscription: SubscriptionModel.fromJson(json['subscription'] ?? {}),
      featured: FeaturedModel.fromJson(json['featured'] ?? {}),
      verification: VerificationModel.fromJson(json['verification'] ?? {}),
      availability: AvailabilityModel.fromJson(json['availability'] ?? {}),
      isVerified: json['verification']?['status'] == 'approved',
      stats: StatsModel.fromJson(json['stats'] ?? {}),
      startingPrice: (json['startingPrice'] ?? json['price'])?.toDouble(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'specialties': specialties,
      'location': (location as LocationModel).toJson(),
      'portfolio': (portfolio as PortfolioModel).toJson(),
      'packages': packages.map((p) => (p as PackageModel).toJson()).toList(),
      'rating': (rating as RatingModel).toJson(),
      'subscription': (subscription as SubscriptionModel).toJson(),
      'featured': (featured as FeaturedModel).toJson(),
      'verification': (verification as VerificationModel).toJson(),
      'isVerified': isVerified,
      'stats': (stats as StatsModel).toJson(),
      'startingPrice': startingPrice,
      'currency': currency,
    };
  }
}

class LocationModel extends Location {
  LocationModel({required super.city, required super.area});

  factory LocationModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return LocationModel(city: '', area: '');
    }
    return LocationModel(city: json['city'] ?? '', area: json['area'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'city': city, 'area': area};
  }
}

class PortfolioModel extends Portfolio {
  PortfolioModel({required super.images, super.video});

  factory PortfolioModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return PortfolioModel(images: []);
    }
    return PortfolioModel(
      images:
          (json['images'] as List?)
              ?.map((i) => PortfolioImageModel.fromJson(i))
              .toList() ??
          [],
      video: json['video'] != null
          ? PortfolioVideoModel.fromJson(json['video'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'images': images.map((i) => (i as PortfolioImageModel).toJson()).toList(),
      'video': video != null ? (video as PortfolioVideoModel).toJson() : null,
    };
  }
}

class PortfolioImageModel extends PortfolioImage {
  PortfolioImageModel({
    super.id,
    required super.url,
    required super.publicId,
    required super.uploadedAt,
  });

  factory PortfolioImageModel.fromJson(dynamic json) {
    // Convert HTTP to HTTPS for security
    String imageUrl = json['url'] ?? '';
    if (imageUrl.startsWith('http://')) {
      imageUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    return PortfolioImageModel(
      id: json['_id'] ?? json['id'],
      url: imageUrl,
      publicId: json['publicId'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'url': url,
      'publicId': publicId,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class PortfolioVideoModel extends PortfolioVideo {
  PortfolioVideoModel({
    required super.url,
    required super.publicId,
    required super.thumbnail,
    required super.duration,
    required super.size,
    required super.uploadedAt,
  });

  factory PortfolioVideoModel.fromJson(dynamic json) {
    // Convert HTTP to HTTPS for security
    String videoUrl = json['url'] ?? '';
    if (videoUrl.startsWith('http://')) {
      videoUrl = videoUrl.replaceFirst('http://', 'https://');
    }

    // Clean video URL - remove transformation parameters that cause 400 error
    // Keep only the base URL without quality/codec parameters
    if (videoUrl.contains('/upload/')) {
      // Extract parts: base + version + path
      final parts = videoUrl.split('/upload/');
      if (parts.length == 2) {
        final base = parts[0];
        final afterUpload = parts[1];

        // Find where the version starts (v1, v2, etc.)
        final versionMatch = RegExp(r'/v\d+/').firstMatch(afterUpload);
        if (versionMatch != null) {
          final versionAndPath = afterUpload.substring(versionMatch.start);
          // Reconstruct clean URL: base/upload/version/path
          videoUrl = '$base/upload$versionAndPath';
        }
      }
    }

    String thumbnailUrl = json['thumbnail'] ?? '';
    if (thumbnailUrl.startsWith('http://')) {
      thumbnailUrl = thumbnailUrl.replaceFirst('http://', 'https://');
    }

    return PortfolioVideoModel(
      url: videoUrl,
      publicId: json['publicId'] ?? '',
      thumbnail: thumbnailUrl,
      duration: (json['duration'] ?? 0).toDouble(),
      size: json['size'] ?? 0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
      'thumbnail': thumbnail,
      'duration': duration,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class PackageModel extends Package {
  PackageModel({
    required super.id,
    required super.name,
    required super.price,
    required super.duration,
    required super.features,
    required super.isActive,
  });

  factory PackageModel.fromJson(dynamic json) {
    return PackageModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'features': features,
      'isActive': isActive,
    };
  }
}

class RatingModel extends Rating {
  RatingModel({required super.average, required super.count});

  factory RatingModel.fromJson(dynamic json) {
    // إذا كان json هو Map
    if (json is Map<String, dynamic>) {
      return RatingModel(
        average: (json['average'] ?? 0).toDouble(),
        count: json['count'] ?? 0,
      );
    }
    // إذا كان json هو double مباشرة (من الكاش القديم)
    if (json is num) {
      return RatingModel(average: json.toDouble(), count: 0);
    }
    // قيمة افتراضية
    return RatingModel(average: 0, count: 0);
  }

  Map<String, dynamic> toJson() {
    return {'average': average, 'count': count};
  }
}

class SubscriptionModel extends Subscription {
  SubscriptionModel({
    required super.plan,
    super.startDate,
    super.endDate,
    required super.isActive,
  });

  factory SubscriptionModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SubscriptionModel(
        plan: 'basic',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        isActive: false,
      );
    }
    return SubscriptionModel(
      plan: json['plan'] ?? 'basic',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class FeaturedModel extends Featured {
  FeaturedModel({required super.isActive, super.startDate, super.endDate});

  factory FeaturedModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return FeaturedModel(isActive: false);
    }
    return FeaturedModel(
      isActive: json['isActive'] ?? false,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

class VerificationModel extends Verification {
  VerificationModel({
    required super.status,
    super.submittedAt,
    super.reviewedAt,
    super.rejectionReason,
    super.documents,
  });

  factory VerificationModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return VerificationModel(status: 'pending');
    }
    return VerificationModel(
      status: json['status'] ?? 'pending',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      documents: json['documents'] != null
          ? VerificationDocumentsModel.fromJson(json['documents'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'documents': documents != null
          ? (documents as VerificationDocumentsModel).toJson()
          : null,
    };
  }
}

class VerificationDocumentsModel extends VerificationDocuments {
  VerificationDocumentsModel({super.idCard, super.portfolioSamples});

  factory VerificationDocumentsModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return VerificationDocumentsModel();
    }
    return VerificationDocumentsModel(
      idCard: json['idCard'],
      portfolioSamples: List<String>.from(json['portfolioSamples'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'idCard': idCard, 'portfolioSamples': portfolioSamples};
  }
}

class AvailabilityModel extends Availability {
  AvailabilityModel({required super.blockedDates});

  factory AvailabilityModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return AvailabilityModel(blockedDates: []);
    }
    return AvailabilityModel(
      blockedDates:
          (json['blockedDates'] as List?)
              ?.map((d) => DateTime.parse(d))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockedDates': blockedDates.map((d) => d.toIso8601String()).toList(),
    };
  }
}

class StatsModel extends Stats {
  StatsModel({
    super.totalBookings,
    super.completedBookings,
    super.totalEarnings,
    super.views,
  });

  factory StatsModel.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return StatsModel();
    }
    return StatsModel(
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      totalEarnings: json['totalEarnings'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'totalEarnings': totalEarnings,
      'views': views,
    };
  }
}
