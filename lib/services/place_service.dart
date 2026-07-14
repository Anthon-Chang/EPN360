import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';

class PlaceService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('places');

  static const double _duplicateThresholdMeters = 30;

  Stream<List<PlaceModel>> streamPlaces() {
    return _collection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<PlaceModel?> getPlaceById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PlaceModel.fromMap(doc.data()!, doc.id);
  }

  Future<PlaceModel> getOrCreateFromCoordinates({
    required double lat,
    required double lng,
    required String name,
    String? address,
    String type = 'evento',
  }) async {
    final snapshot = await _collection.get();

    for (final doc in snapshot.docs) {
      final existing = PlaceModel.fromMap(doc.data(), doc.id);
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        existing.lat,
        existing.lng,
      );
      if (distance <= _duplicateThresholdMeters) {
        return existing;
      }
    }

    final newPlace = PlaceModel(
      id: '',
      name: name,
      type: type,
      lat: lat,
      lng: lng,
      description: address ?? '',
      googlePlaceId: '',
      address: address ?? '',
    );

    final docRef = await _collection.add(newPlace.toMap());
    return PlaceModel(
      id: docRef.id,
      name: newPlace.name,
      type: newPlace.type,
      lat: newPlace.lat,
      lng: newPlace.lng,
      description: newPlace.description,
      googlePlaceId: '',
      address: newPlace.address,
    );
  }

  /// Crea un lugar/punto de interés independiente (edificio, cafetería,
  /// biblioteca, teatro, parqueadero, zona verde, etc.), sin asociarlo a
  /// ningún evento. Se usa desde "Agregar punto de interés" en el mapa.
  Future<void> createPlace({
    required String name,
    required String type,
    required double lat,
    required double lng,
    String description = '',
  }) async {
    final place = PlaceModel(
      id: '',
      name: name,
      type: type,
      lat: lat,
      lng: lng,
      description: description,
      googlePlaceId: '',
      address: '',
    );
    await _collection.add(place.toMap());
  }
}