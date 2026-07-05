import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../models/event_model.dart';
import '../../models/place_model.dart';
import '../../services/event_service.dart';
import '../../services/location_service.dart';
import '../../services/place_service.dart';
import '../../theme/app_colors.dart';

/// Mapa del campus con los lugares registrados y los eventos asociados
/// a cada uno.
///
/// - Si [focusEventId] se recibe, el mapa centra la cámara en el lugar de
///   ese evento y abre automáticamente su ficha de detalle.
/// - Si [focusPlaceId] se recibe (sin [focusEventId]), centra en ese lugar.
/// - Si [selectionMode] es true, el mapa funciona como selector: el usuario
///   toca el mapa para marcar un punto y confirma para devolver esas
///   coordenadas con `Navigator.pop(context, LatLng(...))`.
class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({
    super.key,
    this.focusEventId,
    this.focusPlaceId,
    this.selectionMode = false,
  });

  final String? focusEventId;
  final String? focusPlaceId;
  final bool selectionMode;

  // Coordenadas por defecto del campus EPN (Quito).
  static const double epnLat = -0.2102;
  static const double epnLng = -78.4888;

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  final PlaceService _placeService = PlaceService();
  final EventService _eventService = EventService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  static const LatLng _campusCenter =
      LatLng(PlacesMapPage.epnLat, PlacesMapPage.epnLng);

  LocationResult? _userPosition;
  bool _isLocating = false;
  String? _locationError;
  bool _hasAppliedFocus = false;

  // Punto elegido manualmente por el usuario (solo modo selección).
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _loadUserLocation(showErrors: false);
  }

  Future<void> _loadUserLocation({bool showErrors = true, bool center = false}) async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _userPosition = position);
      if (center) {
        _mapController.move(LatLng(position.lat, position.lng), 17);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() => _locationError = message);
      if (showErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  double? _distanceTo(PlaceModel place) {
    if (_userPosition == null) return null;
    return Geolocator.distanceBetween(
      _userPosition!.lat,
      _userPosition!.lng,
      place.lat,
      place.lng,
    );
  }

  void _confirmSelection() {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toca el mapa para elegir un punto')),
      );
      return;
    }
    Navigator.of(context).pop(_selectedPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode
            ? 'Toca el mapa para elegir el lugar'
            : 'Mapa del campus'),
      ),
      body: StreamBuilder<List<PlaceModel>>(
        stream: _placeService.streamPlaces(),
        builder: (context, placesSnapshot) {
          if (placesSnapshot.hasError) {
            return Center(
              child: Text('Error al cargar lugares: ${placesSnapshot.error}'),
            );
          }
          if (placesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final places = placesSnapshot.data ?? [];

          return StreamBuilder<List<EventModel>>(
            stream: _eventService.streamEvents(),
            builder: (context, eventsSnapshot) {
              final events = eventsSnapshot.data ?? [];

              // Agrupa eventos por lugar.
              final Map<String, List<EventModel>> eventsByPlace = {};
              for (final event in events) {
                eventsByPlace.putIfAbsent(event.placeId, () => []).add(event);
              }

              String? focusPlaceId = widget.focusPlaceId;
              if (focusPlaceId == null && widget.focusEventId != null) {
                for (final e in events) {
                  if (e.id == widget.focusEventId) {
                    focusPlaceId = e.placeId;
                    break;
                  }
                }
              }

              PlaceModel? focusPlace;
              if (focusPlaceId != null) {
                for (final p in places) {
                  if (p.id == focusPlaceId) {
                    focusPlace = p;
                    break;
                  }
                }
              }

              // Centra y abre la ficha del lugar enfocado una sola vez,
              // cuando ya tenemos los datos cargados (no aplica en modo
              // selección).
              if (!widget.selectionMode &&
                  !_hasAppliedFocus &&
                  focusPlace != null) {
                _hasAppliedFocus = true;
                final target = focusPlace;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _mapController.move(LatLng(target.lat, target.lng), 18);
                  _showPlaceDetails(
                    context,
                    target,
                    eventsByPlace[target.id] ?? [],
                  );
                });
              }

              final markers = <Marker>[
                for (final place in places)
                  _buildPlaceMarker(
                    place,
                    eventsByPlace[place.id] ?? [],
                    isFocused: focusPlace?.id == place.id,
                  ),
                if (_userPosition != null) _buildUserMarker(_userPosition!),
                if (widget.selectionMode && _selectedPoint != null)
                  _buildSelectedPointMarker(_selectedPoint!),
              ];

              final initialCenter = focusPlace != null
                  ? LatLng(focusPlace.lat, focusPlace.lng)
                  : _campusCenter;

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: focusPlace != null ? 18 : 17,
                      onTap: widget.selectionMode
                          ? (tapPosition, point) {
                              setState(() => _selectedPoint = point);
                            }
                          : null,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.epn360',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                  if (widget.selectionMode)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app, color: AppColors.epnBlue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Toca cualquier punto del mapa para marcar '
                                  'el lugar del evento',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton(
                      heroTag: 'centerOnUser',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.epnBlue,
                      onPressed: _isLocating
                          ? null
                          : () => _loadUserLocation(center: true),
                      child: _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                  if (widget.selectionMode)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ElevatedButton.icon(
                        onPressed: _confirmSelection,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar esta ubicación'),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Marker _buildPlaceMarker(
    PlaceModel place,
    List<EventModel> eventsHere, {
    bool isFocused = false,
  }) {
    final hasEvents = eventsHere.isNotEmpty;
    final size = isFocused ? 54.0 : 44.0;
    final baseColor = hasEvents ? AppColors.epnGold : AppColors.epnRed;

    return Marker(
      point: LatLng(place.lat, place.lng),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: widget.selectionMode
            ? null
            : () {
                if (eventsHere.length == 1) {
                  _showEventDetails(context, eventsHere.first, place: place);
                } else if (eventsHere.isEmpty) {
                  _showPlaceDetails(context, place, eventsHere);
                } else {
                  _showPlaceDetails(context, place, eventsHere);
                }
              },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: isFocused
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.epnBlue, width: 3),
                    )
                  : null,
              padding: isFocused ? const EdgeInsets.all(3) : EdgeInsets.zero,
              child: Icon(
                hasEvents ? Icons.event : Icons.location_on,
                color: baseColor,
                size: isFocused ? 40 : 36,
              ),
            ),
            if (eventsHere.length > 1)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.epnBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Text(
                    '${eventsHere.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildUserMarker(LocationResult position) {
    return Marker(
      point: LatLng(position.lat, position.lng),
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
          ],
        ),
      ),
    );
  }

  Marker _buildSelectedPointMarker(LatLng point) {
    return Marker(
      point: point,
      width: 48,
      height: 48,
      child: const Icon(
        Icons.location_on,
        color: AppColors.epnBlue,
        size: 48,
      ),
    );
  }

  void _showPlaceDetails(
    BuildContext context,
    PlaceModel place,
    List<EventModel> eventsHere,
  ) {
    final distance = _distanceTo(place);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: eventsHere.isEmpty ? 0.35 : 0.55,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Icon(
                      eventsHere.isNotEmpty ? Icons.event : Icons.place,
                      color: AppColors.epnBlue,
                    ),
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
                if (distance != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk,
                          size: 16, color: AppColors.epnBlue),
                      const SizedBox(width: 4),
                      Text(
                        'A ${_formatDistance(distance)} de tu ubicación',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.epnBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else if (_locationError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Activa tu ubicación para ver la distancia',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 18),
                if (eventsHere.isNotEmpty) ...[
                  Text(
                    eventsHere.length == 1
                        ? 'Evento en este lugar'
                        : 'Eventos en este lugar (${eventsHere.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...eventsHere.map((event) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: AppColors.epnBgLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).pop();
                            _showEventDetails(context, event);
                          },
                          leading: const Icon(Icons.event,
                              color: AppColors.epnGold),
                          title: Text(
                            event.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy – HH:mm')
                                .format(event.date),
                          ),
                          trailing:
                              const Icon(Icons.chevron_right, size: 20),
                        ),
                      )),
                ] else
                  Text(
                    'Aún no hay eventos registrados en este lugar.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra una ficha con la imagen en grande y la información del evento,
  /// igual que en la lista de eventos.
  void _showEventDetails(
    BuildContext context,
    EventModel event, {
    PlaceModel? place,
  }) {
    final dateFormatted = DateFormat('dd/MM/yyyy – HH:mm').format(event.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                _EventDetailImage(imageUrl: event.imageUrl),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.epnBlue),
                          const SizedBox(width: 6),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              color: AppColors.epnBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        event.description,
                        style: const TextStyle(fontSize: 15, height: 2.4),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Imagen grande usada en la ficha de detalle del evento.
class _EventDetailImage extends StatelessWidget {
  const _EventDetailImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.epnGold.withValues(alpha: 0.15),
        child: const Center(
          child: Icon(Icons.event, size: 64, color: AppColors.epnGold),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Image.network(
        imageUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 240,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: AppColors.epnGold.withValues(alpha: 0.15),
            child: const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 48, color: AppColors.epnGold),
            ),
          );
        },
      ),
    );
  }
}