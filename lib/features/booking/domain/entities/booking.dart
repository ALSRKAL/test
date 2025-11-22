class Booking {
  final String id;
  final String clientId;
  final String photographerId;
  final String packageId;
  final String packageName;
  final DateTime date;
  final String timeSlot;
  final String location;
  final String? notes;
  final double price;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  // Additional fields for display
  final String photographerName;
  final String? photographerAvatar;
  final String clientName;
  final String? clientAvatar;

  Booking({
    required this.id,
    required this.clientId,
    required this.photographerId,
    required this.packageId,
    required this.packageName,
    required this.date,
    required this.timeSlot,
    required this.location,
    this.notes,
    required this.price,
    double? totalPrice,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.photographerName = '',
    this.photographerAvatar,
    this.clientName = '',
    this.clientAvatar,
  }) : totalPrice = totalPrice ?? price;
}
