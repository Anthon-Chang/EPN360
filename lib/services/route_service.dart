import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resultado de calcular una ruta a pie entre dos puntos.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// Calcula rutas peatonales usando un servidor OSRM que sí soporta el
/// perfil "foot" (a pie). El demo público de project-osrm.org solo sirve
/// el perfil de auto, así que usamos el de OpenStreetMap.de, que expone
/// perfiles de auto, bici y a pie por separado.
class RouteService {
  static const _baseUrl =
      'https://routing.openstreetmap.de/routed-foot/route/v1/foot';

  Future<RouteResult> getWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coords = '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.parse('$_baseUrl/$coords').replace(queryParameters: {
      'overview': 'full',
      'geometries': 'geojson',
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('No se pudo calcular la ruta (${response.statusCode})');
    }

    final data = json.decode(response.body);
    final routes = data['routes'] as List?;

    if (data['code'] != 'Ok' || routes == null || routes.isEmpty) {
      throw Exception('No se encontró una ruta caminando hasta ese punto');
    }

    final route = routes.first;
    final coordinates = route['geometry']['coordinates'] as List;
    final points = coordinates
        .map<LatLng>(
          (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        )
        .toList();

    return RouteResult(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }
}