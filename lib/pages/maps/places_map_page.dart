import 'dart:async';

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
import '../../services/route_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';

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
  final RouteService _routeService = RouteService();
  final MapController _mapController = MapController();

  // Si está activo, el próximo toque en el mapa agrega un punto de
  // interés nuevo (edificio, cafetería, biblioteca, teatro, etc.).
  bool _addingPoi = false;

  // Ruta peatonal activa (si el usuario presionó "Cómo llegar").
  List<LatLng>? _routePoints;
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  bool _isRoutingLoading = false;
  PlaceModel? _routeDestination;
  StreamSubscription<LocationResult>? _routeLocationSub;
  bool _isRecalculatingRoute = false;

  // Distancia a la que se considera que el usuario ya llegó al evento.
  static const double _arrivalThresholdMeters = 15;

  static const LatLng _campusCenter =
      LatLng(PlacesMapPage.epnLat, PlacesMapPage.epnLng);

  LocationResult? _userPosition;
  bool _isLocating = false;
  String? _locationError;
  bool _hasAppliedFocus = false;

  // Filtro de categoría activo (chips superiores).
  String _selectedFilter = 'Todos';
  static const List<String> _filters = [
    'Todos',
    'Bloques/Aulas',
    'Parqueaderos',
    'Cafeterías',
    'Bibliotecas',
    'Teatro/Recreativo',
    'Zonas Verdes',
    'Solo eventos'
  ];

  // Punto elegido manualmente por el usuario (solo modo selección).
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _loadUserLocation(showErrors: false);
  }

  /// Activa/desactiva el modo "agregar punto de interés". Mientras está
  /// activo, el siguiente toque en el mapa abre el formulario para crear
  /// un lugar nuevo (edificio, cafetería, biblioteca, teatro, etc.) en
  /// esas coordenadas exactas.
  void _toggleAddingPoi() {
    setState(() => _addingPoi = !_addingPoi);
  }

  Future<void> _addPoiAt(LatLng point) async {
    setState(() => _addingPoi = false);

    final result = await _showAddPoiDialog();
    if (result == null || !mounted) return;

    try {
      await _placeService.createPlace(
        name: result.name,
        type: result.category,
        lat: point.latitude,
        lng: point.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${result.name}" agregado al mapa')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  Future<_NewPoiData?> _showAddPoiDialog() {
    final nameController = TextEditingController();
    String category = _filters[1]; // 'Bloques/Aulas' por defecto.

    return showDialog<_NewPoiData>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo punto de interés'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (ej. Biblioteca General)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: _filters
                        .skip(1) // se salta "Todos"
                        .where((f) => f != 'Solo eventos')
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(ctx).pop(
                      _NewPoiData(name: name, category: category),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _routeLocationSub?.cancel();
    super.dispose();
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

  Future<void> _startRoute(PlaceModel place) async {
    Navigator.of(context).maybePop(); // cierra la ficha/bottom sheet si está abierta
    setState(() => _isRoutingLoading = true);

    try {
      var origin = _userPosition;
      origin ??= await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _userPosition = origin);

      final result = await _routeService.getWalkingRoute(
        origin: LatLng(origin.lat, origin.lng),
        destination: LatLng(place.lat, place.lng),
      );

      if (!mounted) return;
      setState(() {
        _routePoints = result.points;
        _routeDistanceMeters = result.distanceMeters;
        _routeDurationSeconds = result.durationSeconds;
        _routeDestination = place;
      });

      final bounds = LatLngBounds.fromPoints(result.points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );

      // Sigue la ubicación del usuario en vivo mientras la ruta esté
      // activa, para ir acortando el camino a medida que se acerca.
      _routeLocationSub?.cancel();
      _routeLocationSub = _locationService
          .watchLocation(distanceFilterMeters: 10)
          .listen(_onUserMovedDuringRoute);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isRoutingLoading = false);
    }
  }

  /// Se llama cada vez que la ubicación del usuario cambia mientras hay
  /// una ruta activa. Recalcula el camino desde la nueva posición y, si
  /// ya está lo bastante cerca, da por terminada la ruta.
  Future<void> _onUserMovedDuringRoute(LocationResult position) async {
    if (!mounted || _routeDestination == null) return;
    setState(() => _userPosition = position);

    final destination = _routeDestination!;
    final distanceToDestination = Geolocator.distanceBetween(
      position.lat,
      position.lng,
      destination.lat,
      destination.lng,
    );

    if (distanceToDestination <= _arrivalThresholdMeters) {
      final destinationName = destination.name;
      _clearRoute();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Llegaste a $destinationName! 🎉')),
      );
      return;
    }

    if (_isRecalculatingRoute) return;
    _isRecalculatingRoute = true;
    try {
      final result = await _routeService.getWalkingRoute(
        origin: LatLng(position.lat, position.lng),
        destination: LatLng(destination.lat, destination.lng),
      );
      if (!mounted || _routeDestination == null) return;
      setState(() {
        _routePoints = result.points;
        _routeDistanceMeters = result.distanceMeters;
        _routeDurationSeconds = result.durationSeconds;
      });
    } catch (_) {
      // Si falla el recálculo puntual se mantiene la ruta anterior;
      // se reintenta en el próximo movimiento.
    } finally {
      _isRecalculatingRoute = false;
    }
  }

  void _clearRoute() {
    _routeLocationSub?.cancel();
    _routeLocationSub = null;
    setState(() {
      _routePoints = null;
      _routeDistanceMeters = null;
      _routeDurationSeconds = null;
      _routeDestination = null;
    });
  }

  /// Distancia entre el último punto de la ruta calculada y las
  /// coordenadas exactas del lugar de destino. Si es mayor a unos pocos
  /// metros, dibujamos un tramo punteado extra (el destino no está
  /// exactamente sobre la vía/camino, ej. una cancha o un patio).
  double? get _finalStretchMeters {
    final points = _routePoints;
    final destination = _routeDestination;
    if (points == null || points.isEmpty || destination == null) return null;
    return Geolocator.distanceBetween(
      points.last.latitude,
      points.last.longitude,
      destination.lat,
      destination.lng,
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  bool _matchesFilter(PlaceModel place, bool hasEvents) {
    if (_selectedFilter == 'Todos') return true;
    if (_selectedFilter == 'Solo eventos') return hasEvents;
    final type = place.type.toLowerCase();
    switch (_selectedFilter) {
      case 'Bloques/Aulas':
        return type.contains('bloque') || type.contains('aula');
      case 'Parqueaderos':
        return type.contains('parqueadero') || type.contains('parking');
      case 'Cafeterías':
        return type.contains('cafeter');
      case 'Bibliotecas':
        return type.contains('bibliotec');
      case 'Teatro/Recreativo':
        return type.contains('teatro');
      case 'Zonas Verdes':
        return type.contains('verde') || type.contains('jardin') ||
            type.contains('jardín');
      default:
        return true;
    }
  }

  IconData _iconForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('cafeter')) return Icons.local_cafe;
    if (normalized.contains('bibliotec')) return Icons.menu_book;
    if (normalized.contains('teatro')) return Icons.theater_comedy;
    if (normalized.contains('parqueadero') || normalized.contains('parking')) {
      return Icons.local_parking;
    }
    if (normalized.contains('verde') || normalized.contains('jardin')) {
      return Icons.park;
    }
    if (normalized.contains('bloque') || normalized.contains('aula')) {
      return Icons.apartment;
    }
    return Icons.location_on;
  }

  Color _colorForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('cafeter')) return Colors.brown;
    if (normalized.contains('bibliotec')) return Colors.indigo;
    if (normalized.contains('teatro')) return Colors.deepPurple;
    if (normalized.contains('parqueadero') || normalized.contains('parking')) {
      return Colors.blueGrey;
    }
    if (normalized.contains('verde') || normalized.contains('jardin')) {
      return Colors.green;
    }
    if (normalized.contains('bloque') || normalized.contains('aula')) {
      return AppColors.epnBlue;
    }
    return AppColors.epnRed;
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            backgroundColor: Colors.white,
            selectedColor: AppColors.epnBlue,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.epnBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.epnBlue : Colors.grey.shade300,
              ),
            ),
            elevation: 2,
            shadowColor: Colors.black26,
          );
        },
      ),
    );
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
      drawer: widget.selectionMode
          ? null
          : const AppDrawer(currentRoute: AppDrawer.map),
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

              final visiblePlaces = places
                  .where((p) =>
                      _matchesFilter(p, eventsByPlace[p.id]?.isNotEmpty ?? false))
                  .toList();

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
                for (final place in visiblePlaces)
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
                          : _addingPoi
                              ? (tapPosition, point) => _addPoiAt(point)
                              : null,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.epn360',
                      ),
                      if (_routePoints != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints!,
                              strokeWidth: 6,
                              color: AppColors.epnBlue,
                              borderColor: Colors.white,
                              borderStrokeWidth: 1.5,
                            ),
                            // Tramo final punteado: cuando el destino no
                            // está exactamente sobre la vía/camino (ej. una
                            // cancha o un patio), como hace Google Maps.
                            if (_routeDestination != null &&
                                _finalStretchMeters != null &&
                                _finalStretchMeters! > 3)
                              Polyline(
                                points: [
                                  _routePoints!.last,
                                  LatLng(_routeDestination!.lat,
                                      _routeDestination!.lng),
                                ],
                                strokeWidth: 4,
                                color: AppColors.epnBlue,
                                pattern: const StrokePattern.dotted(),
                              ),
                          ],
                        ),
                      if (_routePoints != null)
                        CircleLayer(
                          circles: [
                            // Punto donde termina la vía/camino transitable.
                            CircleMarker(
                              point: _routePoints!.last,
                              radius: 5,
                              color: Colors.white,
                              borderColor: AppColors.epnBlue,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                  if (!widget.selectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: _buildFilterChips(),
                    ),
                  if (_addingPoi)
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
                              Icon(Icons.add_location_alt,
                                  color: AppColors.epnBlue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Toca el mapa donde quieres agregar el '
                                  'punto de interés',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                  if (_routePoints != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 90,
                      child: Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_walk,
                                  color: AppColors.epnBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _routeDestination?.name ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${_formatDistance(_routeDistanceMeters ?? 0)} · '
                                      '${_formatDuration(_routeDurationSeconds ?? 0)} caminando',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _clearRoute,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 72,
                    child: FloatingActionButton.small(
                      heroTag: 'addPoi',
                      backgroundColor:
                          _addingPoi ? AppColors.epnGold : Colors.white,
                      foregroundColor: AppColors.epnBlue,
                      onPressed: widget.selectionMode ? null : _toggleAddingPoi,
                      child: Icon(
                        _addingPoi ? Icons.close : Icons.add_location_alt,
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
    final baseColor =
        hasEvents ? AppColors.epnGold : _colorForCategory(place.type);

    final String? thumbnailUrl =
        hasEvents && eventsHere.first.imageUrl.isNotEmpty
            ? eventsHere.first.imageUrl
            : null;

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
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: isFocused ? AppColors.epnBlue : baseColor,
                  width: isFocused ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: thumbnailUrl != null
                  ? ClipOval(
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: size * 0.4,
                              height: size * 0.4,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Si la imagen no carga, cae al ícono normal.
                          return Icon(
                            Icons.event,
                            color: baseColor,
                            size: isFocused ? 28 : 24,
                          );
                        },
                      ),
                    )
                  : Icon(
                      hasEvents ? Icons.event : _iconForCategory(place.type),
                      color: baseColor,
                      size: isFocused ? 28 : 24,
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isRoutingLoading ? null : () => _startRoute(place),
                    icon: _isRoutingLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.directions),
                    label: Text(
                        _isRoutingLoading ? 'Calculando ruta...' : 'Cómo llegar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.epnBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
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
                            Navigator.of(ctx).pop();
                            if (context.mounted) {
                              _showEventDetails(context, event, place: place);
                            }
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
                      if (place != null) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _startRoute(place);
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Cómo llegar al evento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.epnBlue,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
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

/// Datos del formulario para crear un punto de interés nuevo.
class _NewPoiData {
  final String name;
  final String category;

  _NewPoiData({required this.name, required this.category});
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