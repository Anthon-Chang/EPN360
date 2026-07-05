import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String title;
  final String description;
  final String imageUrl;
  final String enlace;
  final DateTime createdAt;

  NewsModel({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.enlace,
    required this.createdAt,
  });

  // Guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'enlace': enlace,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Leer desde Firestore
  factory NewsModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NewsModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      enlace: map['enlace'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}