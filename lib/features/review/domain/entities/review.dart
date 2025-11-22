class ReviewReply {
  final String text;
  final DateTime repliedAt;

  ReviewReply({
    required this.text,
    required this.repliedAt,
  });
}

class Review {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientAvatar;
  final String photographerId;
  final String bookingId;
  final String? packageName;
  final DateTime? bookingDate;
  final double rating;
  final String comment;
  final ReviewReply? reply;
  final bool isReported;
  final String? reportReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    required this.photographerId,
    required this.bookingId,
    this.packageName,
    this.bookingDate,
    required this.rating,
    required this.comment,
    this.reply,
    this.isReported = false,
    this.reportReason,
    required this.createdAt,
    this.updatedAt,
  });
}
