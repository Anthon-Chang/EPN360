class UserModel {
  final String uid;
  final String name;
  final String email;
  final String career;
<<<<<<< HEAD
  final String role; // 'Estudiante' o 'Visitante'
  final String photoUrl;
  final List<String> favoriteEventIds;
=======
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.career,
<<<<<<< HEAD
    this.role = 'Estudiante',
    this.photoUrl = '',
    this.favoriteEventIds = const [],
  });

  /// Inicial del nombre para mostrar como avatar por defecto.
  String get initial => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

=======
  });

>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
  // Convert to Map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'career': career,
<<<<<<< HEAD
      'role': role,
      'photoUrl': photoUrl,
      'favoriteEventIds': favoriteEventIds,
=======
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
    };
  }

  // Create from Map (usually reading from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      career: map['career'] ?? '',
<<<<<<< HEAD
      role: map['role'] ?? 'Estudiante',
      photoUrl: map['photoUrl'] ?? '',
      favoriteEventIds: List<String>.from(map['favoriteEventIds'] ?? const []),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? career,
    String? role,
    String? photoUrl,
    List<String>? favoriteEventIds,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      career: career ?? this.career,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteEventIds: favoriteEventIds ?? this.favoriteEventIds,
=======
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
    );
  }
}
