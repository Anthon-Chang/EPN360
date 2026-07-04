import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double lat;
  final double lng;

  LocationResult({required this.lat, required this.lng});
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    // 1. Verifica que el GPS/servicio de ubicación esté encendido
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Activa el GPS/ubicación de tu dispositivo para continuar',
      );
    }

    // 2. Verifica y solicita permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está denegado permanentemente. '
        'Habilítalo desde los ajustes de la app.',
      );
    }

    // 3. Obtiene la posición actual con buena precisión
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LocationResult(lat: position.latitude, lng: position.longitude);
  }
}