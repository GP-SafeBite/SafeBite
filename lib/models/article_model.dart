// Article Model - Represent an educational article sourced from SFDA or Ministry of Health

class ArticleModel {
  final String title;
  final String description;
  final String link;
  final String imageUrl;
  final String pubDate;
  final String source;

  ArticleModel({
    required this.title,
    required this.description,
    required this.link,
    required this.imageUrl,
    required this.pubDate,
    required this.source,
  });
}