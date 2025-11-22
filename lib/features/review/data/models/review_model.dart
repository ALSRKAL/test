import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  ReviewModel({
    required super.id,
    required super.clientId,
    required super.clientName,
    super.clientAvatar,
    required super.photographerId,
    required super.bookingId,
    super.packageName,
    super.bookingDate,
    required super.rating,
    required super.comment,
    super.reply,
    super.isReported,
    super.reportReason,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Extract client info
    final client = json['client'];
    final clientId = client is Map<String, dynamic>
        ? (client['_id'] as String? ?? '')
        : (client as String? ?? '');
    final clientName = client is Map<String, dynamic>
        ? (client['name'] as String? ?? 'عميل')
        : 'عميل';
    final clientAvatar = client is Map<String, dynamic>
        ? (client['avatar'] as String?)
        : null;

    // Extract booking info
    final booking = json['booking'];
    final bookingId = booking is Map<String, dynamic>
        ? (booking['_id'] as String? ?? '')
        : (booking as String? ?? '');
    final packageName = booking is Map<String, dynamic>
        ? (booking['package']?['name'] as String?)
        : null;
    final bookingDate = booking is Map<String, dynamic> && booking['date'] != null
        ? DateTime.tryParse(booking['date'])
        : null;

    // Extract photographer ID
    final photographer = json['photographer'];
    final photographerId = photographer is Map<String, dynamic>
        ? (photographer['_id'] as String? ?? '')
        : (photographer as String? ?? '');

    // Extract reply
    ReviewReply? reply;
    if (json['reply'] != null && json['reply']['text'] != null) {
      reply = ReviewReply(
        text: json['reply']['text'],
        repliedAt: DateTime.parse(json['reply']['repliedAt']),
      );
    }

    return ReviewModel(
      id: json['_id'] ?? json['id'],
      clientId: clientId,
      clientName: clientName,
      clientAvatar: clientAvatar,
      photographerId: photographerId,
      bookingId: bookingId,
      packageName: packageName,
      bookingDate: bookingDate,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      reply: reply,
      isReported: json['isReported'] ?? false,
      reportReason: json['reportReason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'photographer': photographerId,
      'booking': bookingId,
      'packageName': packageName,
      'bookingDate': bookingDate?.toIso8601String(),
      'rating': rating,
      'comment': comment,
      'reply': reply != null
          ? {
              'text': reply!.text,
              'repliedAt': reply!.repliedAt.toIso8601String(),
            }
          : null,
      'isReported': isReported,
      'reportReason': reportReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
