import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_model.dart';
import '../../theme/app_colors.dart';

/// Pantalla de lectura de una noticia: imagen a pantalla completa,
/// cuerpo del artículo y opción de compartir el enlace original.
class DetalleNoticiaScreen extends StatelessWidget {
  final NewsModel noticia;

  const DetalleNoticiaScreen({super.key, required this.noticia});

  Future<void> _openOriginal(BuildContext context) async {
    final url = noticia.enlace.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL vacía')),
      );
      return;
    }

    final uri = Uri.parse(url);

    try {
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede abrir la URL')),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _share() {
    final link = noticia.enlace.trim();
    final text = link.isEmpty
        ? noticia.title
        : '${noticia.title}\n\nLee la nota completa: $link';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.epnBlue,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Compartir',
                onPressed: _share,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: noticia.imageUrl.isEmpty
                  ? Container(color: AppColors.epnBlue)
                  : Image.network(
                      noticia.imageUrl,
                      fit: BoxFit.cover,
                      headers: const {'User-Agent': 'Mozilla/5.0'},
                      errorBuilder: (c, e, s) => Container(
                        color: AppColors.epnBlue,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white54, size: 48),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        'Lectura: ${_estimatedReadTime(noticia.description)} min',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    noticia.description,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openOriginal(context),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir noticia original'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Compartir'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Estima el tiempo de lectura a ~200 palabras por minuto.
  int _estimatedReadTime(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final minutes = (words.length / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }
}
