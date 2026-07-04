class PlaceModel {
  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String description;

  PlaceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.description,
  });

  // Convert to Map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'lat': lat,
      'lng': lng,
      'description': description,
    };
  }

  // Create from Map (usually reading from Firestore)
  factory PlaceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PlaceModel(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
    );
  }
}
