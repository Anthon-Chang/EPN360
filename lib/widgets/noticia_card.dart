import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../pages/news/detalle_noticia_screen.dart';
<<<<<<< HEAD
import '../theme/app_colors.dart';
=======
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a

class NoticiaCard extends StatelessWidget {
  final NewsModel noticia;

  const NoticiaCard({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              noticia.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              headers: const {
                "User-Agent": "Mozilla/5.0"
              },
              errorBuilder: (c, e, s) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noticia.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  noticia.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
<<<<<<< HEAD
                      backgroundColor: AppColors.epnBlue,
=======
                      backgroundColor: const Color(0xFF1A4B7C),
>>>>>>> 84a46a42d8be785d3557f68e63d439025265fb2a
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalleNoticiaScreen(noticia: noticia),
                        ),
                      );
                    },
                    child: const Text("Leer más"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}