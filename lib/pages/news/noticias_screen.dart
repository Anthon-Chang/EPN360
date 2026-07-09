import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/new_service.dart';
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar noticias"));
          }

          final noticias = snapshot.data ?? [];

          return ListView.builder(
            itemCount: noticias.length,
            itemBuilder: (context, index) {
              return NoticiaCard(noticia: noticias[index]);
            },
          );
        },
      ),
    );
  }
}