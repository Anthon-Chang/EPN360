const { onRequest } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const cheerio = require('cheerio');

const BASE_URL = 'https://www.epn.edu.ec/category/noticias/page/';
const MAX_PAGES = 10;

async function fetchNoticias() {
  const noticias = [];

  for (let page = 1; page <= MAX_PAGES; page++) {
    const response = await fetch(`${BASE_URL}${page}/`, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
          '(KHTML, like Gecko) Chrome/125.0 Safari/537.36',
      },
    });

    if (!response.ok) break;

    const html = await response.text();
    const $ = cheerio.load(html);
    const items = $('.edubin-post-one-single-grid');

    if (items.length === 0) break;

    items.each((_, el) => {
      const titleLink = $(el).find('.course__title-link').first();
      const title = titleLink.text().trim();
      const enlace = titleLink.attr('href') || '';
      const description = $(el).find('.card-bottom p').first().text().trim();
      const img = $(el).find('img').first();
      const imageUrl =
        img.attr('data-lazy-src') ||
        img.attr('data-src') ||
        img.attr('src') ||
        '';

      if (title) {
        noticias.push({
          title,
          description,
          imageUrl,
          enlace,
          createdAt: new Date().toISOString(),
        });
      }
    });
  }

  return noticias;
}

exports.getNoticias = onRequest(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  async (req, res) => {
    try {
      const noticias = await fetchNoticias();
      res.set('Cache-Control', 'public, max-age=600, s-maxage=1800');
      res.status(200).json({ noticias });
    } catch (error) {
      logger.error('Error obteniendo noticias:', error);
      res.status(500).json({ error: 'No se pudieron obtener las noticias' });
    }
  }
);