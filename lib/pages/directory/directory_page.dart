import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';

class _Contact {
  const _Contact({
    required this.name,
    required this.schedule,
    required this.phone,
    required this.email,
  });

  final String name;
  final String schedule;
  final String phone;
  final String email;
}

class _ContactGroup {
  const _ContactGroup({
    required this.title,
    required this.icon,
    required this.contacts,
  });

  final String title;
  final IconData icon;
  final List<_Contact> contacts;
}

/// Directorio básico de contactos del campus, pensado para estudiantes
/// y visitantes.
class DirectoryPage extends StatelessWidget {
  const DirectoryPage({super.key});

  static final List<_ContactGroup> _groups = [
    const _ContactGroup(
      title: 'Emergencias y Seguridad',
      icon: Icons.local_police_outlined,
      contacts: [
        _Contact(
          name: 'Guardias de seguridad (Caseta principal)',
          schedule: 'Lun-Dom 00:00 - 23:59',
          phone: '+593998765432',
          email: 'seguridad@epn.edu.ec',
        ),
        _Contact(
          name: 'Dispensario médico / Servicios de salud',
          schedule: 'Lun-Vie 07:30 - 17:00',
          phone: '+59322507144',
          email: 'dispensario@epn.edu.ec',
        ),
        _Contact(
          name: 'Soporte técnico / Departamento de TI',
          schedule: 'Lun-Vie 08:00 - 17:00',
          phone: '+59322976300',
          email: 'soporte.ti@epn.edu.ec',
        ),
      ],
    ),
    const _ContactGroup(
      title: 'Gestión Académica y Servicios',
      icon: Icons.apartment_outlined,
      contacts: [
        _Contact(
          name: 'Secretaría General / Admisiones',
          schedule: 'Lun-Vie 08:00 - 16:30',
          phone: '+59322976300',
          email: 'secretaria.general@epn.edu.ec',
        ),
        _Contact(
          name: 'Bienestar Estudiantil',
          schedule: 'Lun-Vie 08:00 - 17:00',
          phone: '+59322976300',
          email: 'bienestar@epn.edu.ec',
        ),
        _Contact(
          name: 'Biblioteca Central',
          schedule: 'Lun-Vie 07:30 - 19:00',
          phone: '+59322976300',
          email: 'biblioteca@epn.edu.ec',
        ),
      ],
    ),
    const _ContactGroup(
      title: 'Transporte y Accesos',
      icon: Icons.directions_bus_outlined,
      contacts: [
        _Contact(
          name: 'Transporte universitario / Parqueaderos',
          schedule: 'Lun-Vie 06:30 - 20:00',
          phone: '+59322976300',
          email: 'transporte@epn.edu.ec',
        ),
      ],
    ),
  ];

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de llamadas')),
      );
    }
  }

  Future<void> _email(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de correo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.epnBgLight,
      drawer: const AppDrawer(currentRoute: AppDrawer.directory),
      appBar: AppBar(title: const Text('Directorio')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              leading: Icon(group.icon, color: AppColors.epnBlue),
              title: Text(
                group.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: group.contacts
                  .map((contact) => _ContactTile(
                        contact: contact,
                        onCall: () => _call(context, contact.phone),
                        onEmail: () => _email(context, contact.email),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onCall,
    required this.onEmail,
  });

  final _Contact contact;
  final VoidCallback onCall;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        contact.schedule,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.phone, color: AppColors.epnBlue),
            tooltip: 'Llamar',
          ),
          IconButton(
            onPressed: onEmail,
            icon: const Icon(Icons.email_outlined, color: AppColors.epnBlue),
            tooltip: 'Enviar correo',
          ),
        ],
      ),
    );
  }
}
