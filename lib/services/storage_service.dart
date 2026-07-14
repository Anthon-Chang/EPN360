import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube bytes de imagen a Firebase Storage. Usar bytes (en vez de
  /// `dart:io File`) hace que esto funcione tanto en Flutter Web como
  /// en Android/iOS/Desktop.
  ///
  /// [bytes] es el contenido del archivo a subir.
  /// [path] es la ruta destino en el bucket (ej. 'news/image_123.jpg').
  ///
  /// Devuelve la URL de descarga, o [null] si falla.
  Future<String?> uploadFile(
    Uint8List bytes,
    String path, {
    String contentType = 'image/jpeg',
  }) async {
    try {
      final Reference ref = _storage.ref().child(path);

      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = ref.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file to Firebase Storage: $e');
      return null;
    }
  }

  /// Elimina un archivo de Firebase Storage dado su path o URL completa.
  Future<bool> deleteFile(String pathOrUrl) async {
    try {
      Reference ref;
      if (pathOrUrl.startsWith('http')) {
        ref = _storage.refFromURL(pathOrUrl);
      } else {
        ref = _storage.ref().child(pathOrUrl);
      }
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file from Firebase Storage: $e');
      return false;
    }
  }
}
