import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/news_model.dart';

/// Consume la Cloud Function `getNoticias`, que hace el scraping del
/// sitio de la EPN del lado del servidor. Así evitamos el bloqueo de
/// CORS que ocurre al llamar directamente a www.epn.edu.ec desde
/// Flutter Web, y mantenemos la lógica de scraping en un solo lugar.
///
/// IMPORTANTE: reemplaza `_projectId` solo si cambias de proyecto de
/// Firebase. La región debe coincidir con la configurada en
/// `functions/index.js` (por defecto: us-central1).
class NewsService {
  static const String _projectId = 'epn360-e218b';
  static const String _region = 'us-central1';
  static const String _functionUrl =
      'https://$_region-$_projectId.cloudfunctions.net/getNoticias';

  Future<List<NewsModel>> obtenerNoticias() async {
    final response = await http.get(Uri.parse(_functionUrl));

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron obtener las noticias (${response.statusCode})',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> data = body['noticias'] ?? [];

    return data.map((item) {
      return NewsModel(
        title: item['title'] ?? '',
        description: item['description'] ?? '',
        imageUrl: item['imageUrl'] ?? '',
        enlace: item['enlace'] ?? '',
        createdAt: DateTime.tryParse(item['createdAt'] ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }
}