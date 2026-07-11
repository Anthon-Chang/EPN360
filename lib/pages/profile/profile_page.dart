import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/image_helper.dart';
import '../../widgets/app_drawer.dart';
import '../auth/login_page.dart';

/// Pantalla de perfil del usuario: datos de la cuenta, información
/// académica/de visita, eventos agendados y acciones de cuenta.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _userService = UserService();
  final _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      backgroundColor: AppColors.epnBgLight,
      drawer: const AppDrawer(currentRoute: AppDrawer.profile),
      appBar: AppBar(title: const Text('Mi perfil')),
      body: StreamBuilder<UserModel?>(
        stream: _userService.streamUserProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('No se encontró tu perfil.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(context, user),
              const SizedBox(height: 20),
              _buildInfoPanel(user),
              const SizedBox(height: 20),
              _buildFavorites(user),
              const SizedBox(height: 20),
              _buildActions(context, user),
            ],
          );
        },
      ),
    );
  }

  // --- Cabecera de identidad -----------------------------------------

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.epnGold,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? Text(
                        user.initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _changePhoto(context, user),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.epnBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name.isEmpty ? 'Sin nombre' : user.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (user.role == 'Estudiante'
                      ? AppColors.epnBlue
                      : AppColors.epnGold)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: user.role == 'Estudiante'
                    ? AppColors.epnBlue
                    : AppColors.epnGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePhoto(BuildContext context, UserModel user) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImageHelper.pickAndCompressImage(source: source);
    if (picked == null) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final url = await StorageService().uploadFile(
      picked.bytes,
      'users/${user.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (!context.mounted) return;
    Navigator.of(context).pop(); // cierra el loader

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la foto')),
      );
      return;
    }

    await _userService.updateFields(user.uid, {'photoUrl': url});
  }

  // --- Panel académico / de visita ------------------------------------

  Widget _buildInfoPanel(UserModel user) {
    final isStudent = user.role == 'Estudiante';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStudent ? 'Información académica' : 'Información de la visita',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isStudent ? Icons.school_outlined : Icons.badge_outlined,
                size: 18,
                color: AppColors.epnBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isStudent
                      ? (user.career.isEmpty
                          ? 'Carrera no registrada'
                          : user.career)
                      : (user.career.isEmpty
                          ? 'Motivo de visita no registrado'
                          : user.career),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Mis eventos agendados -------------------------------------------

  Widget _buildFavorites(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Eventos Agendados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (user.favoriteEventIds.isEmpty)
            const Text(
              'Aún no has agendado eventos. Ve a "Eventos" y marca '
              'los que te interesen.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            )
          else
            StreamBuilder<List<EventModel>>(
              stream: _eventService.streamEvents(),
              builder: (context, snapshot) {
                final events = (snapshot.data ?? [])
                    .where((e) => user.favoriteEventIds.contains(e.id))
                    .toList();

                if (events.isEmpty) {
                  return const Text(
                    'Aún no has agendado eventos.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  );
                }

                return Column(
                  children: events
                      .map((event) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_available,
                                color: AppColors.epnGold),
                            title: Text(event.title),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy – HH:mm')
                                  .format(event.date),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Quitar de agendados',
                              onPressed: () => _userService.removeFavoriteEvent(
                                  user.uid, event.id),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Acciones de cuenta ------------------------------------------------

  Widget _buildActions(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _editProfile(context, user),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar perfil'),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _logout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.epnRed,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.epnRed),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _editProfile(BuildContext context, UserModel user) async {
    final nameController = TextEditingController(text: user.name);
    final careerController = TextEditingController(text: user.career);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: careerController,
              decoration: InputDecoration(
                labelText:
                    user.role == 'Estudiante' ? 'Carrera' : 'Motivo de visita',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _userService.updateFields(user.uid, {
        'name': nameController.text.trim(),
        'career': careerController.text.trim(),
      });
    }
  }
}
