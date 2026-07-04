import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('events');

  Stream<List<EventModel>> streamEvents() {
    return _collection.orderBy('date', descending: false).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Obtiene un único evento por id.
  Future<EventModel?> getEventById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return EventModel.fromMap(doc.data()!, doc.id);
  }

  /// Crea un nuevo evento. Retorna el id generado por Firestore.
  Future<String> createEvent(EventModel event) async {
    final docRef = await _collection.add(event.toMap());
    return docRef.id;
  }

  /// Actualiza un evento existente.
  Future<void> updateEvent(EventModel event) async {
    await _collection.doc(event.id).update(event.toMap());
  }

  /// Elimina un evento por id.
  Future<void> deleteEvent(String id) async {
    await _collection.doc(id).delete();
  }
}
