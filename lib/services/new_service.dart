import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';

import '../models/news_model.dart';

/// Servicio de noticias: hace scraping directo del sitio de la EPN.
///
/// En Flutter Web, el navegador bloquea la petición directa a
/// www.epn.edu.ec por política de CORS (el sitio no envía las
/// cabeceras necesarias). Para evitarlo, en web pasamos la petición
/// a través de un proxy CORS público; en Android/iOS/Desktop no hace
/// falta, así que se llama directo.
class NewsService {
  static const String baseUrl = "https://www.epn.edu.ec/category/noticias/page/";

  /// Prefijo de proxy CORS usado solo en Web. Si en algún momento este
  /// servicio deja de funcionar, se puede reemplazar por otro proxy
  /// público (ej. https://api.allorigins.win/raw?url=) sin tocar el
  /// resto del código.
  static const String _corsProxy = "https://corsproxy.io/?url=";

  String _resolveUrl(String url) {
    if (!kIsWeb) return url;
    return "$_corsProxy${Uri.encodeComponent(url)}";
  }

  Future<List<NewsModel>> obtenerNoticias() async {
    List<NewsModel> noticias = [];

    for (int page = 1; page <= 10; page++) {
      final targetUrl = "$baseUrl$page/";
      final response = await http.get(Uri.parse(_resolveUrl(targetUrl)));

      if (response.statusCode != 200) break;

      final document = parse(response.body);

      final noticiasHtml =
          document.getElementsByClassName("edubin-post-one-single-grid");

      if (noticiasHtml.isEmpty) break;

      for (var noticia in noticiasHtml) {
        final title =
            noticia.querySelector(".course__title-link")?.text.trim() ?? "";

        final enlace =
            noticia.querySelector(".course__title-link")?.attributes["href"] ?? "";

        final description =
            noticia.querySelector(".card-bottom p")?.text.trim() ?? "";

        final img = noticia.querySelector("img");

        final image =
            img?.attributes["data-lazy-src"] ??
            img?.attributes["data-src"] ??
            img?.attributes["src"] ??
            "";

        noticias.add(
          NewsModel(
            title: title,
            description: description,
            imageUrl: image.isEmpty ? "" : _resolveUrl(image),
            enlace: enlace,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return noticias;
  }
}
