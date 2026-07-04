import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String placeId;
  final String description;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.placeId,
    required this.description,
  });

  // Convert to Map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'placeId': placeId,
      'description': description,
    };
  }

  // Create from Map (usually reading from Firestore)
  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.parse(map['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return EventModel(
      id: documentId,
      title: map['title'] ?? '',
      date: parsedDate,
      placeId: map['placeId'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
