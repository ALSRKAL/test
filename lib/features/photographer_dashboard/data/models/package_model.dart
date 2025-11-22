class PackageModel {
  final String? id;
  final String name;
  final double price;
  final String duration;
  final List<String> features;
  final bool isActive;

  PackageModel({
    this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    this.isActive = true,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['_id'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as String,
      features: (json['features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'features': features,
      'isActive': isActive,
    };
  }

  PackageModel copyWith({
    String? id,
    String? name,
    double? price,
    String? duration,
    List<String>? features,
    bool? isActive,
  }) {
    return PackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
    );
  }
}
