import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/new_service.dart';
<<<<<<< HEAD
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/noticia_card.dart';
import 'detalle_noticia_screen.dart';

class NoticiasScreen extends StatelessWidget {
  const NoticiasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NewsService();

    return Scaffold(
      backgroundColor: AppColors.epnBgLight,
      drawer: const AppDrawer(currentRoute: AppDrawer.news),
      appBar: AppBar(title: const Text('Noticias EPN')),
      body: FutureBuilder<List<NewsModel>>(
        future: service.obtenerNoticias(),
=======
import '../../widgets/noticia_card.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  late Future<List<NewsModel>> _futureNoticias;

  @override
  void initState() {
    super.initState();
    _futureNoticias = NewsService().obtenerNoticias();
  }

  Future<void> _recargarNoticias() async {
    setState(() {
      _futureNoticias = NewsService().obtenerNoticias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Noticias EPN"),
        backgroundColor: const Color(0xFF1A4B7C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargarNoticias,
          ),
        ],
      ),
      body: FutureBuilder<List<NewsModel>>(
        future: _futureNoticias,
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
<<<<<<< HEAD
            return const Center(child: Text('Error al cargar noticias'));
=======
            return const Center(child: Text("Error al cargar noticias"));
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
          }

          final noticias = snapshot.data ?? [];

<<<<<<< HEAD
          if (noticias.isEmpty) {
            return const Center(child: Text('No hay noticias disponibles.'));
          }

          final destacada = noticias.first;
          final resto = noticias.skip(1).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Última hora',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.epnBlue,
                  ),
                ),
              ),
              _HeroNoticia(noticia: destacada),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Más noticias',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.epnBlue,
                  ),
                ),
              ),
              ...resto.map((noticia) => NoticiaCard(noticia: noticia)),
            ],
=======
          return ListView.builder(
            itemCount: noticias.length,
            itemBuilder: (context, index) {
              return NoticiaCard(noticia: noticias[index]);
            },
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
          );
        },
      ),
    );
  }
<<<<<<< HEAD
}

/// Tarjeta destacada (hero) con la noticia más reciente del feed.
class _HeroNoticia extends StatelessWidget {
  const _HeroNoticia({required this.noticia});

  final NewsModel noticia;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleNoticiaScreen(noticia: noticia),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: noticia.imageUrl.isEmpty
                    ? Container(color: AppColors.epnBlue)
                    : Image.network(
                        noticia.imageUrl,
                        fit: BoxFit.cover,
                        headers: const {'User-Agent': 'Mozilla/5.0'},
                        errorBuilder: (c, e, s) =>
                            Container(color: AppColors.epnBlue),
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  noticia.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
=======
}
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
