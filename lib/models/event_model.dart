import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String placeId;
  final String description;
  final String imageUrl;
  final String authorId; 

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.placeId,
    required this.description,
    required this.authorId, 
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'placeId': placeId,
      'description': description,
      'imageUrl': imageUrl,
      'authorId': authorId, 
    };
  }

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
      imageUrl: map['imageUrl'] ?? '',
      authorId: map['authorId'] ?? '', 
    );
  }

  EventModel copyWith({
    String? title,
    DateTime? date,
    String? placeId,
    String? description,
    String? imageUrl,
    String? authorId,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      placeId: placeId ?? this.placeId,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId, 
    );
  }
}