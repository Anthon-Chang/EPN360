import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_model.dart';

class DetalleNoticiaScreen extends StatelessWidget {
  final NewsModel noticia;

  const DetalleNoticiaScreen({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(noticia.title),
        backgroundColor: const Color(0xFF1A4B7C),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              noticia.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(noticia.description),

                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A4B7C),
                    ),
                    onPressed: () async {
                      final url = noticia.enlace.trim();

                      if (url.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("URL vacía")),
                        );
                        return;
                      }

                      final uri = Uri.parse(url);

                      try {
                        final canLaunch = await canLaunchUrl(uri);

                        if (!canLaunch) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No se puede abrir la URL")),
                          );
                          return;
                        }

                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    child: const Text("Abrir noticia original"),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}