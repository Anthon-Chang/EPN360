import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/new_service.dart';
import '../../widgets/noticia_card.dart';

class NoticiasScreen extends StatelessWidget {
  const NoticiasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NewsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Noticias EPN"),
        backgroundColor: const Color(0xFF1A4B7C),
      ),
      body: FutureBuilder<List<NewsModel>>(
        future: service.obtenerNoticias(),
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