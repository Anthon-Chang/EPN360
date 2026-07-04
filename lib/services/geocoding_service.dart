import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/reverse';

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'accept-language': 'es',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'EPN360App/1.0 (uso académico EPN)'},
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}