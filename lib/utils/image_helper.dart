import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the specified [source] (camera or gallery)
  /// and automatically compresses it using native platform capabilities
  /// to save storage space and bandwidth.
  ///
  /// [quality] is a value from 0 to 100 representing the image compression quality.
  /// [maxWidth] and [maxHeight] restrict the maximum dimensions of the image.
  ///
  /// Returns a [File] pointing to the compressed image, or [null] if cancelled/failed.
  static Future<File?> pickAndCompressImage({
    required ImageSource source,
    int quality = 70, // 70 is the sweet spot between size reduction and visual quality
    double maxWidth = 1024, // 1024px is standard for modern mobile app displays
    double maxHeight = 1024,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      return null;
    }
  }
}

