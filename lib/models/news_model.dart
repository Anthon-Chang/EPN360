import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final DateTime createdAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.createdAt,
  });

  // Convert to Map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Map (usually reading from Firestore)
  factory NewsModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.parse(map['createdAt']);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return NewsModel(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: parsedCreatedAt,
    );
  }
}
