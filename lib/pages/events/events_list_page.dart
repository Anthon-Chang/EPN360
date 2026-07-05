import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';
import 'event_form_page.dart';
import '../maps/places_map_page.dart';

class EventsListPage extends StatelessWidget {
  EventsListPage({super.key});

  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver mapa del campus',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlacesMapPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventService.streamEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar eventos: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no hay eventos registrados.\nToca el botón + para crear el primero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(
                event: event,
                onShowDetails: () => _showEventDetails(context, event),
                onEdit: () => _openForm(context, event: event),
                onDelete: () => _confirmDelete(context, event),
                onShowOnMap: () => _openMap(context, event),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {EventModel? event}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventFormPage(event: event)),
    );
  }

  void _openMap(BuildContext context, EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlacesMapPage(focusEventId: event.id),
      ),
    );
  }

  /// Muestra una ficha con la imagen en grande y la información del evento.
  void _showEventDetails(BuildContext context, EventModel event) {
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _openMap(context, event);
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Ver mapa'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _openForm(context, event: event);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                          ),
                        ],
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

  Future<void> _confirmDelete(BuildContext context, EventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Seguro que deseas eliminar "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.epnRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _eventService.deleteEvent(event.id);
    }
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

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onShowDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onShowOnMap,
  });

  final EventModel event;
  final VoidCallback onShowDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowOnMap;

  Widget _buildLeading() {
    final hasImage = event.imageUrl.isNotEmpty;

    if (!hasImage) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.epnGold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.event, color: AppColors.epnGold),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        event.imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 48,
            height: 48,
            color: Colors.grey.shade200,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.epnGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: AppColors.epnGold),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy – HH:mm').format(event.date);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onShowDetails,
        leading: _buildLeading(),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$dateFormatted\n${event.description}'),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'map') onShowOnMap();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'map',
              child: ListTile(
                leading: Icon(Icons.map_outlined),
                title: Text('Ver mapa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}