class UserModel {
  final String uid;
  final String name;
  final String email;
  final String career;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.career,
  });

  // Convert to Map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'career': career,
    };
  }

  // Create from Map (usually reading from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      career: map['career'] ?? '',
    );
  }
}
