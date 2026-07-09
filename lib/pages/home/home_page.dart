import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../events/event_form_page.dart';
import '../events/events_list_page.dart';
import '../maps/places_map_page.dart';
import '../news/noticias_screen.dart';
import '../directory/directory_page.dart';
import '../profile/profile_page.dart';

/// Pantalla principal (Home) de EPN 360.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _socialLinks = {
    'facebook': 'https://www.facebook.com/EPNQuito/',
    'instagram': 'https://www.instagram.com/epn_ecuador/',
    'tiktok': 'https://www.tiktok.com/@epnecuador',
  };

  Future<void> _openSocial(String key) async {
    final uri = Uri.parse(_socialLinks[key]!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.epnBgLight,
      drawer: const AppDrawer(currentRoute: AppDrawer.home),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Home'),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menú',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingHeader(context, uid),
              const SizedBox(height: 8),
              _buildDateStrip(),
              const SizedBox(height: 20),
              _buildSectionTitle('Lo Último en el Campus'),
              const SizedBox(height: 12),
              _buildFeaturedCarousel(context),
              const SizedBox(height: 24),
              _buildQuickAccess(context),
              const SizedBox(height: 24),
              _buildSocialRow(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Encabezado con saludo y avatar ---------------------------------

  Widget _buildGreetingHeader(BuildContext context, String? uid) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: uid == null
                ? const Text(
                    '¡Hola!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.epnBlue,
                    ),
                  )
                : StreamBuilder<UserModel?>(
                    stream: UserService().streamUserProfile(uid),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final name =
                          user?.name.isNotEmpty == true ? user!.name : '';
                      return Text(
                        name.isEmpty ? '¡Hola!' : '¡Hola, $name!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.epnBlue,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: uid == null
                ? const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.epnGold,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                : StreamBuilder<UserModel?>(
                    stream: UserService().streamUserProfile(uid),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final hasPhoto = user?.photoUrl.isNotEmpty == true;
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.epnGold,
                        backgroundImage:
                            hasPhoto ? NetworkImage(user!.photoUrl) : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                user?.initial ?? '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    final today =
        DateFormat("EEEE d 'de' MMMM", 'es_ES').format(DateTime.now());
    final capitalized = today[0].toUpperCase() + today.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 16, color: AppColors.epnGold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$capitalized · Campus EPN activo',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.epnBlue,
        ),
      ),
    );
  }

  // --- Carrusel de los 3 eventos más recientes -------------------------

  Widget _buildFeaturedCarousel(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: EventService().streamEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return _buildEmptyEventsState(context);
        }

        final featured = events.take(3).toList();

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _FeaturedCard(event: featured[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyEventsState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_busy, size: 40, color: AppColors.epnGold),
            const SizedBox(height: 12),
            const Text(
              'No hay eventos programados para hoy. ¡Crea uno nuevo!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventFormPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear evento'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Accesos rápidos ---------------------------------------------------

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      _QuickAccess(
          'Mapa Campus',
          Icons.map_outlined,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlacesMapPage()))),
      _QuickAccess(
          'Eventos',
          Icons.event_outlined,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EventsListPage()))),
      _QuickAccess(
          'Noticias',
          Icons.article_outlined,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NoticiasScreen()))),
      _QuickAccess(
          'Directorio',
          Icons.contact_phone_outlined,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DirectoryPage()))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Accesos rápidos'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: items.map((item) => _QuickAccessTile(item)).toList(),
          ),
        ),
      ],
    );
  }

  // --- Redes sociales ----------------------------------------------------

  Widget _buildSocialRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Síguenos'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _SocialButton(
                icon: Icons.facebook,
                onTap: () => _openSocial('facebook'),
              ),
              const SizedBox(width: 14),
              _SocialButton(
                icon: Icons.camera_alt_outlined,
                onTap: () => _openSocial('instagram'),
              ),
              const SizedBox(width: 14),
              _SocialButton(
                icon: Icons.music_note_outlined,
                onTap: () => _openSocial('tiktok'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAccess {
  _QuickAccess(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile(this.item);
  final _QuickAccess item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.epnBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.epnBlue),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.epnBlue,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy').format(event.date);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventsListPage()),
      ),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: event.imageUrl.isEmpty
                  ? Container(
                      color: AppColors.epnGold.withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(Icons.event,
                            size: 36, color: AppColors.epnGold),
                      ),
                    )
                  : Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: AppColors.epnGold.withValues(alpha: 0.15),
                        child: const Center(
                          child: Icon(Icons.event,
                              size: 36, color: AppColors.epnGold),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormatted,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.epnBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
