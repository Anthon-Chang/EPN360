import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('users');

  /// Crea o actualiza el perfil de un usuario recién registrado.
  Future<void> createUserProfile(UserModel user) async {
    await _collection.doc(user.uid).set(user.toMap());
  }

  /// Obtiene el perfil de un usuario por su uid.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Actualiza el perfil de un usuario existente.
  Future<void> updateUserProfile(UserModel user) async {
    await _collection.doc(user.uid).update(user.toMap());
  }
}
