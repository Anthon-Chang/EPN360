import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Imagen seleccionada por el usuario, ya leída en memoria como bytes.
/// Usar bytes (en vez de `dart:io File`) permite que el mismo código
/// funcione tanto en Flutter Web como en Android/iOS/Desktop, ya que
/// `dart:io.File` no está soportado en la web.
class PickedImage {
  const PickedImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Abre la cámara o galería según [source], comprime la imagen usando
  /// las capacidades nativas de `image_picker` y devuelve sus bytes.
  ///
  /// Funciona igual en Web, Android, iOS y Desktop.
  static Future<PickedImage?> pickAndCompressImage({
    required ImageSource source,
    int quality = 70,
    double maxWidth = 1024,
    double maxHeight = 1024,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      return PickedImage(bytes: bytes, name: pickedFile.name);
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
      return null;
    }
  }
}
