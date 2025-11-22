import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  BookingModel({
    required super.id,
    required super.clientId,
    required super.photographerId,
    required super.packageId,
    required super.packageName,
    required super.date,
    required super.timeSlot,
    required super.location,
    super.notes,
    required super.price,
    super.totalPrice,
    required super.status,
    required super.createdAt,
    super.confirmedAt,
    super.completedAt,
    super.cancelledAt,
    super.cancellationReason,
    super.photographerName,
    super.photographerAvatar,
    super.clientName,
    super.clientAvatar,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Extract price from payment object or package
    final payment = json['payment'] as Map<String, dynamic>?;
    final package = json['package'] as Map<String, dynamic>?;
    final price =
        (payment?['amount'] ?? package?['price'] ?? json['price'] ?? 0)
            .toDouble();

    // Extract client ID
    final client = json['client'];
    final clientId = client is Map<String, dynamic>
        ? (client['_id'] as String? ?? '')
        : (client as String? ?? '');

    // Extract photographer ID
    final photographer = json['photographer'];
    final photographerId = photographer is Map<String, dynamic>
        ? (photographer['_id'] as String? ?? '')
        : (photographer as String? ?? '');

    // Extract package ID
    final packageData = json['package'];
    final packageId = packageData is Map<String, dynamic>
        ? (packageData['_id'] as String? ?? '')
        : (packageData as String? ?? '');

    // Extract photographer name and avatar
    final photographerData = photographer is Map<String, dynamic>
        ? photographer
        : null;
    final photographerUser = photographerData?['user'] as Map<String, dynamic>?;
    final photographerName =
        photographerUser?['name'] as String? ??
        photographerData?['name'] as String? ??
        'مصورة';
    final photographerAvatar =
        photographerUser?['avatar'] as String? ??
        photographerData?['avatar'] as String?;

    // Extract client name and avatar
    final clientData = client is Map<String, dynamic> ? client : null;
    final clientName = clientData?['name'] as String? ?? 'عميل';
    final clientAvatar = clientData?['avatar'] as String?;

    return BookingModel(
      id: json['_id'] ?? json['id'],
      clientId: clientId,
      photographerId: photographerId,
      packageId: packageId,
      packageName: package?['name'] ?? json['packageName'] ?? 'باقة',
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'],
      price: price,
      totalPrice: price,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      photographerName: photographerName,
      photographerAvatar: photographerAvatar,
      clientName: clientName,
      clientAvatar: clientAvatar,
      cancellationReason:
          json['cancellation']?['reason'] ?? json['cancellationReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': clientId,
      'photographer': photographerId,
      'package': packageId,
      'packageName': packageName,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'location': location,
      'notes': notes,
      'price': price,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }
}
