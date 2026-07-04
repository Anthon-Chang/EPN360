import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/place_model.dart';
import '../../services/place_service.dart';
import '../../theme/app_colors.dart';

class PlacesMapPage extends StatelessWidget {
  PlacesMapPage({super.key});

  final PlaceService _placeService = PlaceService();

  // Centro aproximado del campus EPN (Quito)
  static const LatLng _epnCenter = LatLng(-0.2103, -78.4917);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa del campus')),
      body: StreamBuilder<List<PlaceModel>>(
        stream: _placeService.streamPlaces(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar lugares: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final places = snapshot.data ?? [];

          final markers = places.map((place) {
            return Marker(
              point: LatLng(place.lat, place.lng),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _showPlaceDetails(context, place),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.epnRed,
                  size: 40,
                ),
              ),
            );
          }).toList();

          final center = places.isNotEmpty
              ? LatLng(places.first.lat, places.first.lng)
              : _epnCenter;

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.epn360',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }

  void _showPlaceDetails(BuildContext context, PlaceModel place) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.place, color: AppColors.epnBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (place.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(place.address,
                    style: const TextStyle(color: Colors.black54)),
              ],
              const SizedBox(height: 8),
              Text(
                'Lat: ${place.lat.toStringAsFixed(5)}, '
                'Lng: ${place.lng.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}