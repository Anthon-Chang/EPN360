import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/place_model.dart';
import '../../services/event_service.dart';
import '../../services/place_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/image_helper.dart';
import '../../widgets/current_location_picker.dart';


class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key, this.event});

  final EventModel? event;

  bool get isEditing => event != null;

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  final _placeService = PlaceService();
  final _storageService = StorageService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedDate;
  PlaceModel? _selectedPlace;
  PlaceModel? _initialPlace;
  File? _newImageFile;
  String? _existingImageUrl;

  bool _isSaving = false;
  bool _isLoadingInitialPlace = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController =
        TextEditingController(text: event?.description ?? '');
    _selectedDate = event?.date;
    _existingImageUrl = event?.imageUrl;

    if (event != null && event.placeId.isNotEmpty) {
      _loadInitialPlace(event.placeId);
    }
  }

  Future<void> _loadInitialPlace(String placeId) async {
    setState(() => _isLoadingInitialPlace = true);
    final place = await _placeService.getPlaceById(placeId);
    if (!mounted) return;
    setState(() {
      _initialPlace = place;
      _selectedPlace = place;
      _isLoadingInitialPlace = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Evita registrar eventos en fechas ya pasadas.
    if (combined.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha y hora deben ser futuras'),
        ),
      );
      return;
    }

    setState(() => _selectedDate = combined);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImageHelper.pickAndCompressImage(source: source);
    if (file == null) return;
    setState(() => _newImageFile = file);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha del evento')),
      );
      return;
    }
    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el lugar del evento')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String imageUrl = _existingImageUrl ?? '';

      if (_newImageFile != null) {
        final fileName =
            'events/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadedUrl =
            await _storageService.uploadFile(_newImageFile!, fileName);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final event = EventModel(
        id: widget.event?.id ?? '',
        title: _titleController.text.trim(),
        date: _selectedDate!,
        placeId: _selectedPlace!.id,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );

      if (widget.isEditing) {
        await _eventService.updateEvent(event);
      } else {
        await _eventService.createEvent(event);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildImagePreview() {
    if (_newImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(_newImageFile!, height: 160, fit: BoxFit.cover),
      );
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            Image.network(_existingImageUrl!, height: 160, fit: BoxFit.cover),
      );
    }
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar evento' : 'Nuevo evento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título: 5-80 caracteres, sin límite estricto de tipo de
                // carácter (permite letras, números y puntuación básica).
                TextFormField(
                  controller: _titleController,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título del evento',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Ingresa un título';
                    if (v.length < 5) {
                      return 'El título debe tener al menos 5 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(10),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Toca para seleccionar'
                          : DateFormat('dd/MM/yyyy – HH:mm')
                              .format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoadingInitialPlace)
                  const Center(child: CircularProgressIndicator())
                else
                  CurrentLocationPicker(
                    initialPlace: _initialPlace,
                    onPlaceSelected: (place) {
                      setState(() => _selectedPlace = place);
                    },
                  ),
                const SizedBox(height: 16),

                // Descripción: 10-500 caracteres
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Ingresa una descripción';
                    if (v.length < 10) {
                      return 'La descripción debe tener al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Imagen del evento',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                _buildImagePreview(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isEditing
                          ? 'Guardar cambios'
                          : 'Crear evento'),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.epnBlue,
                      side: const BorderSide(color: AppColors.epnBlue),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}