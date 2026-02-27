import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import '../models/article_model.dart';

class ArticlesService {

  // 🔴 RSS feed URLs
  static const String _sfdaFoodUrl =
      'http://www.sfda.gov.sa/ar/news.xml?tags=1';

  //static const String _mohHealthTipsUrl =
  //    'https://www.moh.gov.sa/_layouts/15/moh/RssGenerator.aspx?WebSiteUrl=/HealthAwareness/EducationalContent/HealthTips/&ListUrl=/HealthAwareness/EducationalContent/HealthTips/Pages/&ViewName=RSSView&RssTitle=&RssDescription=BriefDesc';

  //static const String _mohBlogUrl =
      //'https://www.moh.gov.sa/_Layouts/moh/RssGenerator.aspx?WebSiteUrl=/HealthAwareness/EducationalContent/Blog/1439/&ListUrl=/HealthAwareness/EducationalContent/Blog/1439/Pages/&ViewName=RSSView&RssTitle=&RssDescription=';

  // 🔴 allergy/food keywords to filter articles
  static const List<String> _keywords = [
  // حساسية
  'حساسية',
  'تحسس',
  'مسببات',

  // غذاء عام - food general
  'غذاء',
  'غذائي',
  'غذائية',
  'أغذية',
  'الأغذية',
  'طعام',
  'الطعام',
  'مكونات',
  'المكونات',
  'منتج',
  'منتجات',
  'سلامة',
  'تغذية',
  'صحة',
  'مستهلك',
  'ملصق',
  'عبوة',
  'food',
  'safety',
  'nutrition',
  'product',
  'health',
];

  // 🔴 fetch all articles from all 3 feeds
  static Future<List<ArticleModel>> fetchAllArticles() async {
    final List<ArticleModel> allArticles = [];

    final results = await Future.wait([
      _fetchFeed(url: _sfdaFoodUrl, source: 'SFDA'),
   //   _fetchFeed(url: _mohHealthTipsUrl, source: 'MOH'),
     // _fetchFeed(url: _mohBlogUrl, source: 'MOH'),
    ]);

    for (final list in results) {
      allArticles.addAll(list);
    }

    // 🔴 sort by date (newest first)
    allArticles.sort((a, b) => b.pubDate.compareTo(a.pubDate));

    return allArticles;
  }

  // 🔴 fetch and parse single RSS feed
  static Future<List<ArticleModel>> _fetchFeed({
    required String url,
    required String source,
  }) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) return [];

      // 🔴 parse RSS XML
      final feed = RssFeed.parse(response.body);
      final List<ArticleModel> articles = [];

      for (final item in feed.items) {
        final title = item.title ?? '';
        final description = item.description ?? '';
        final link = item.link ?? '';
        final pubDate = item.pubDate ?? '';

        // 🔴 extract image from media or enclosure
        String imageUrl = '';
        if (item.media?.contents?.isNotEmpty == true) {
          imageUrl = item.media!.contents!.first.url ?? '';
        } else if (item.enclosure?.url != null) {
          imageUrl = item.enclosure!.url!;
        }

        // 🔴 filter: only include allergy/food related
        if (_isRelevant(title: title, description: description)) {
          articles.add(ArticleModel(
            title: title,
            description: _cleanDescription(description),
            link: link,
            imageUrl: imageUrl,
            pubDate: pubDate,
            source: source,
          ));
        }
      }

      return articles;
    } catch (e) {
      print('❌ RSS fetch error ($source): $e');
      return [];
    }
  }

  // 🔴 check if article is food/allergy related
  static bool _isRelevant({
    required String title,
    required String description,
  }) {
    final text = '$title $description'.toLowerCase();
    return _keywords.any((keyword) => text.contains(keyword));
  }

  // 🔴 clean HTML tags from description
  static String _cleanDescription(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}