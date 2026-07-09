import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file (e.g., a compressed image) to Firebase Storage.
  ///
  /// [file] is the local file to upload.
  /// [path] is the destination path in the storage bucket (e.g. 'news/image_123.jpg').
  ///
  /// Returns the download URL string, or [null] if the upload fails.
  Future<String?> uploadFile(File file, String path) async {
    try {
      // Create a reference to the storage location
      final Reference ref = _storage.ref().child(path);

      // Specify metadata (helpful for browser rendering and caching)
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Start the upload task
      final UploadTask uploadTask = ref.putFile(file, metadata);

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;

      // Get and return the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file to Firebase Storage: $e');
      return null;
    }
  }

  /// Deletes a file from Firebase Storage given its path or full download URL.
  ///
  /// Returns [true] if successful, [false] otherwise.
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

