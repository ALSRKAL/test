class Photographer {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? avatar;
  final String? bio;
  final List<String> specialties;
  final Location location;
  final Portfolio portfolio;
  final List<Package> packages;
  final Rating rating;
  final Subscription subscription;
  final Featured featured;
  final Verification verification;
  final Availability availability;
  final bool isVerified;
  final Stats stats;
  final double? startingPrice;
  final String? currency;

  Photographer({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    this.bio,
    required this.specialties,
    required this.location,
    required this.portfolio,
    required this.packages,
    required this.rating,
    required this.subscription,
    required this.featured,
    required this.verification,
    required this.availability,
    this.isVerified = false,
    required this.stats,
    this.startingPrice,
    this.currency,
  });
}

class Location {
  final String city;
  final String area;

  Location({required this.city, required this.area});
}

class Portfolio {
  final List<PortfolioImage> images;
  final PortfolioVideo? video;

  Portfolio({required this.images, this.video});
}

class PortfolioImage {
  final String? id; // MongoDB _id
  final String url;
  final String publicId;
  final DateTime uploadedAt;

  PortfolioImage({
    this.id,
    required this.url,
    required this.publicId,
    required this.uploadedAt,
  });
}

class PortfolioVideo {
  final String url;
  final String publicId;
  final String thumbnail;
  final double duration;
  final int size;
  final DateTime uploadedAt;

  PortfolioVideo({
    required this.url,
    required this.publicId,
    required this.thumbnail,
    required this.duration,
    required this.size,
    required this.uploadedAt,
  });
}

class Package {
  final String id;
  final String name;
  final double price;
  final String duration;
  final List<String> features;
  final bool isActive;

  Package({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    required this.isActive,
  });
}

class Rating {
  final double average;
  final int count;

  Rating({required this.average, required this.count});
}

class Subscription {
  final String plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  Subscription({
    required this.plan,
    this.startDate,
    this.endDate,
    required this.isActive,
  });
}

class Featured {
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  Featured({required this.isActive, this.startDate, this.endDate});
}

class Verification {
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final VerificationDocuments? documents;

  Verification({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.documents,
  });
}

class VerificationDocuments {
  final String? idCard;
  final List<String> portfolioSamples;

  VerificationDocuments({this.idCard, this.portfolioSamples = const []});
}

class Availability {
  final List<DateTime> blockedDates;

  Availability({required this.blockedDates});
}

class Stats {
  final int totalBookings;
  final int completedBookings;
  final int totalEarnings;
  final int views;

  Stats({
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.totalEarnings = 0,
    this.views = 0,
  });
}
