import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';

import '../models/news_model.dart';

class NewsService {
  static const String baseUrl =
      "https://www.epn.edu.ec/category/noticias/page/";

  Future<List<NewsModel>> obtenerNoticias() async {
    List<NewsModel> noticias = [];

    for (int page = 1; page <= 10; page++) {
      final response = await http.get(Uri.parse("$baseUrl$page/"));

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
            imageUrl: image,
            enlace: enlace,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return noticias;
  }
}