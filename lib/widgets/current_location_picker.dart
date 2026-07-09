import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../pages/maps/places_map_page.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../theme/app_colors.dart';

class CurrentLocationPicker extends StatefulWidget {
  const CurrentLocationPicker({
    super.key,
    required this.onPlaceSelected,
    this.initialPlace,
  });

  final ValueChanged<PlaceModel> onPlaceSelected;
  final PlaceModel? initialPlace;

  @override
  State<CurrentLocationPicker> createState() => _CurrentLocationPickerState();
}

class _CurrentLocationPickerState extends State<CurrentLocationPicker> {
  final _locationService = LocationService();
  final _geocodingService = GeocodingService();
  final _placeService = PlaceService();
  final _nameController = TextEditingController();

  PlaceModel? _resolvedPlace;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlace != null) {
      _resolvedPlace = widget.initialPlace;
      _nameController.text = widget.initialPlace!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      await _resolveAndSetPlace(lat: location.lat, lng: location.lng);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickOnMap() async {
    final selected = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => const PlacesMapPage(selectionMode: true),
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _resolveAndSetPlace(
        lat: selected.latitude,
        lng: selected.longitude,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Resuelve la dirección (reverse geocoding) y crea/reutiliza el
  /// [PlaceModel] correspondiente a las coordenadas dadas.
  Future<void> _resolveAndSetPlace({
    required double lat,
    required double lng,
  }) async {
    final address = await _geocodingService.reverseGeocode(lat, lng);

    final defaultName = address ?? 'Ubicación del evento';
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : defaultName;

    final place = await _placeService.getOrCreateFromCoordinates(
      lat: lat,
      lng: lng,
      name: name,
      address: address,
    );

    if (!mounted) return;
    setState(() {
      _resolvedPlace = place;
      _nameController.text = place.name;
    });
    widget.onPlaceSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Lugar del evento',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          validator: (value) => (_resolvedPlace == null)
              ? 'Usa tu ubicación actual o elígela en el mapa'
              : null,
          onChanged: (value) {
            if (_resolvedPlace != null && value.trim().isNotEmpty) {
              widget.onPlaceSelected(
                PlaceModel(
                  id: _resolvedPlace!.id,
                  name: value.trim(),
                  type: _resolvedPlace!.type,
                  lat: _resolvedPlace!.lat,
                  lng: _resolvedPlace!.lng,
                  description: _resolvedPlace!.description,
                  googlePlaceId: _resolvedPlace!.googlePlaceId,
                  address: _resolvedPlace!.address,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _useCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Mi ubicación'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickOnMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Elegir en el mapa'),
              ),
            ),
          ],
        ),
        if (_resolvedPlace != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '📍 Lat: ${_resolvedPlace!.lat.toStringAsFixed(5)}, '
              'Lng: ${_resolvedPlace!.lng.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppColors.epnRed),
            ),
          ),
      ],
    );
  }
}