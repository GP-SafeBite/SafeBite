import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_model.dart';

class ArticlesService {
  static Future<List<ArticleModel>> fetchAllArticles() async {
    return _hardcodedArticles;
  }

  static bool isPdf(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  // ✅ Fixed PDF launcher
  static Future<void> openPdf(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: try platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('❌ Could not open PDF: $e');
    }
  }

  static final List<ArticleModel> _hardcodedArticles = [
    ArticleModel(
      title: 'الحساسية الغذائية',
      description:
          'تعرّف على الحساسية الغذائية وأسبابها وأعراضها وطرق تشخيصها وعلاجها.',
      link: 'http://www.sfda.gov.sa/ar/awarenessarticle/78126',
      imageUrl: '',
      pubDate: '2019-08-18',
      source: 'SFDA',
    ),
    ArticleModel(
      title: 'الحساسية الغذائية - دليل شامل (PDF)',
      description:
          'دليل توعوي شامل من وزارة الصحة حول الحساسية الغذائية وأنواعها.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/HealthyLifestyle/Documents/Food-Allergy.pdf',
      imageUrl: '',
      pubDate: '2024-01-01',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'الإسعافات الأولية لحالات الحساسية',
      description:
          'تعلّم كيفية التعامل مع ردود الفعل التحسسية في حالات الطوارئ.',
      link:
          'https://www.moh.gov.sa/healthawareness/educationalcontent/firstaid/pages/009.aspx',
      imageUrl: '',
      pubDate: '2024-01-02',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'حساسية الفول السوداني',
      description:
          'حساسية الفول السوداني من أكثر أنواع الحساسية خطورة. تعرّف على أعراضها وطرق تجنبها.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/healthylifestyle/pages/peanutsallergy.aspx',
      imageUrl: '',
      pubDate: '2024-01-03',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'حساسية الفول السوداني - دليل تفصيلي (PDF)',
      description:
          'دليل تفصيلي من وزارة الصحة عن حساسية الفول السوداني والبدائل الغذائية الآمنة.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/HealthyLifestyle/Documents/Peanuts-Allergy.pdf',
      imageUrl: '',
      pubDate: '2024-01-04',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'مرض السيلياك وحساسية الغلوتين',
      description:
          'مرض السيلياك اضطراب مناعي يُصيب الأمعاء عند تناول الغلوتين. تعرّف على أعراضه وعلاجه.',
      link:
          'https://www.moh.gov.sa/healthawareness/educationalcontent/diseases/noncommunicable/pages/celiacdisease.aspx',
      imageUrl: '',
      pubDate: '2024-01-05',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'برنامج الغذاء الخالي من الغلوتين (PDF)',
      description:
          'تعرّف على برنامج وزارة الصحة للغذاء الخالي من الغلوتين والمنتجات المتاحة في السوق السعودي.',
      link:
          'https://www.moh.gov.sa/en/Ministry/MediaCenter/Ads/Documents/Gluten-Free-Food-Program.pdf',
      imageUrl: '',
      pubDate: '2024-01-06',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'عدم تحمل اللاكتوز',
      description:
          'عدم تحمل اللاكتوز يختلف عن حساسية الحليب. تعرّف على أعراضه والبدائل الغذائية المناسبة.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/healthylifestyle/pages/lactoseintolerance.aspx',
      imageUrl: '',
      pubDate: '2024-01-07',
      source: 'MOH',
    ),
    ArticleModel(
      title: 'مرض السيلياك - دليل شامل (PDF)',
      description:
          'دليل شامل من وزارة الصحة عن مرض السيلياك والنصائح الغذائية للمصابين.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/HealthyLifestyle/Documents/Celiac-Disease.pdf',
      imageUrl: '',
      pubDate: '2024-01-08',
      source: 'MOH',
    ),
  ];

  // ✅ Emoji for each article (by index)
  static const List<String> articleEmojis = [
    '🍽️', // الحساسية الغذائية
    '📋', // دليل شامل PDF
    '🚑', // إسعافات أولية
    '🥜', // الفول السوداني
    '📄', // الفول السوداني PDF
    '🌾', // السيلياك
    '📄', // الغلوتين PDF
    '🥛', // اللاكتوز
    '📄', // السيلياك PDF
  ];

  // ✅ Background color for each article card
  static const List<Color> articleColors = [
    Color(0xFFE8F5E9), // green
    Color(0xFFE3F2FD), // blue
    Color(0xFFFFEBEE), // red
    Color(0xFFFFF8E1), // yellow
    Color(0xFFF3E5F5), // purple
    Color(0xFFFBE9E7), // orange
    Color(0xFFE0F7FA), // cyan
    Color(0xFFF1F8E9), // light green
    Color(0xFFEDE7F6), // deep purple
  ];
}