class SavedPlace {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final DateTime createdAt;
  final String? notes;
  final String? category; // home, work, favorite, other
  double? distance; // Add this field for calculated distance

  SavedPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    DateTime? createdAt,
    this.notes,
    this.category,
    this.distance, // Add to constructor
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'category': category,
      // Note: distance is not saved as it's calculated dynamically
    };
  }

  // Create from JSON
  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      placeId: json['placeId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      notes: json['notes'],
      category: json['category'],
      // distance is not loaded from JSON
    );
  }

  // Create a copy with updated fields
  SavedPlace copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? createdAt,
    String? notes,
    String? category,
    double? distance,
  }) {
    return SavedPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      distance: distance ?? this.distance,
    );
  }

  @override
  String toString() {
    return 'SavedPlace{id: $id, name: $name, address: $address}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedPlace && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
