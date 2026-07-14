import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../pages/home/home_page.dart';
import '../pages/maps/places_map_page.dart';
import '../pages/events/events_list_page.dart';
import '../pages/news/noticias_screen.dart';
import '../pages/directory/directory_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/auth/login_page.dart';

/// Menú lateral (hamburguesa) con los accesos principales de la app:
/// Mapa Campus, Eventos, Noticias y Directorio, además de Home y Perfil.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute = ''});

  /// Identificador de la pantalla actual, para resaltarla en el menú.
  final String currentRoute;

  static const String home = 'home';
  static const String map = 'map';
  static const String events = 'events';
  static const String news = 'news';
  static const String directory = 'directory';
  static const String profile = 'profile';

  void _goTo(BuildContext context, String route) {
    Navigator.of(context).pop(); // cierra el drawer
    if (route == currentRoute) return;

    Widget page;
    switch (route) {
      case home:
        page = const HomePage();
        break;
      case map:
        page = PlacesMapPage();
        break;
      case events:
        page = EventsListPage();
        break;
      case news:
        page = const NoticiasScreen();
        break;
      case directory:
        page = const DirectoryPage();
        break;
      case profile:
        page = const ProfilePage();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
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
      if (!context.mounted) return;
      Navigator.of(context).pop(); // cierra el drawer
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(uid),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: currentRoute == home,
              onTap: () => _goTo(context, home),
            ),
            _DrawerItem(
              icon: Icons.map_outlined,
              label: 'Mapa Campus',
              selected: currentRoute == map,
              onTap: () => _goTo(context, map),
            ),
            _DrawerItem(
              icon: Icons.event_outlined,
              label: 'Eventos',
              selected: currentRoute == events,
              onTap: () => _goTo(context, events),
            ),
            _DrawerItem(
              icon: Icons.article_outlined,
              label: 'Noticias',
              selected: currentRoute == news,
              onTap: () => _goTo(context, news),
            ),
            _DrawerItem(
              icon: Icons.contact_phone_outlined,
              label: 'Directorio',
              selected: currentRoute == directory,
              onTap: () => _goTo(context, directory),
            ),
            const Divider(height: 24),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              selected: currentRoute == profile,
              onTap: () => _goTo(context, profile),
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              color: AppColors.epnRed,
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? uid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      color: AppColors.epnBlue,
      child: uid == null
          ? const _HeaderContent(name: 'EPN 360', subtitle: '')
          : StreamBuilder<UserModel?>(
              stream: UserService().streamUserProfile(uid),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return _HeaderContent(
                  name: user?.name.isNotEmpty == true ? user!.name : 'EPN 360',
                  subtitle: user?.email ?? '',
                  initial: user?.initial ?? 'E',
                );
              },
            ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.name,
    required this.subtitle,
    this.initial = 'E',
  });

  final String name;
  final String subtitle;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.epnGold,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (selected ? AppColors.epnBlue : Colors.black87);
    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.epnGold.withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}
