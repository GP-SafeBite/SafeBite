class ArticleModel {
  final String title;
  final String description;
  final String link;
  final String imageUrl;
  final String pubDate;
  final String source; // 'SFDA' or 'MOH'

  ArticleModel({
    required this.title,
    required this.description,
    required this.link,
    required this.imageUrl,
    required this.pubDate,
    required this.source,
  });
}