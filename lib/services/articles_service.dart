// Articles Service - Provide educational food allergy articles from hardcoded SFDA and MOH sources

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_model.dart';

class ArticlesService {
  // Return the full list of available educational articles
  static Future<List<ArticleModel>> fetchAllArticles() async {
    return _hardcodedArticles;
  }

  // Determine whether a URL points to a PDF document
  static bool isPdf(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  // Open a PDF URL in an external application, falling back to the platform default if needed
  static Future<void> openPdf(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
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
      source: 'هيئة الغذاء والدواء',
    ),
    ArticleModel(
      title: 'الحساسية الغذائية - دليل شامل (PDF)',
      description:
          'دليل توعوي شامل من وزارة الصحة حول الحساسية الغذائية وأنواعها.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/HealthyLifestyle/Documents/Food-Allergy.pdf',
      imageUrl: '',
      pubDate: '2024-01-01',
      source: 'وزارة الصحة',
    ),
    ArticleModel(
      title: 'الإسعافات الأولية لحالات الحساسية',
      description:
          'تعلّم كيفية التعامل مع ردود الفعل التحسسية في حالات الطوارئ.',
      link:
          'https://www.moh.gov.sa/healthawareness/educationalcontent/firstaid/pages/009.aspx',
      imageUrl: '',
      pubDate: '2024-01-02',
      source: 'وزارة الصحة',
    ),
    ArticleModel(
      title: 'حساسية الفول السوداني',
      description:
          'حساسية الفول السوداني من أكثر أنواع الحساسية خطورة. تعرّف على أعراضها وطرق تجنبها.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/healthylifestyle/pages/peanutsallergy.aspx',
      imageUrl: '',
      pubDate: '2024-01-03',
      source: 'وزارة الصحة',
    ),
    ArticleModel(
      title: 'حساسية الفول السوداني - دليل تفصيلي (PDF)',
      description:
          'دليل تفصيلي من وزارة الصحة عن حساسية الفول السوداني والبدائل الغذائية الآمنة.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/HealthyLifestyle/Documents/Peanuts-Allergy.pdf',
      imageUrl: '',
      pubDate: '2024-01-04',
      source: 'وزارة الصحة',
    ),
    ArticleModel(
      title: 'مرض السيلياك وحساسية الغلوتين',
      description:
          'مرض السيلياك اضطراب مناعي يُصيب الأمعاء عند تناول الغلوتين. تعرّف على أعراضه وعلاجه.',
      link:
          'https://www.moh.gov.sa/healthawareness/educationalcontent/diseases/noncommunicable/pages/celiacdisease.aspx',
      imageUrl: '',
      pubDate: '2024-01-05',
      source: 'وزارة الصحة',
    ),
    ArticleModel(
      title: 'برنامج الغذاء الخالي من الغلوتين (PDF)',
      description:
          'تعرّف على برنامج وزارة الصحة للغذاء الخالي من الغلوتين والمنتجات المتاحة في السوق السعودي.',
      link:
          'https://www.moh.gov.sa/en/Ministry/MediaCenter/Ads/Documents/Gluten-Free-Food-Program.pdf',
      imageUrl: '',
      pubDate: '2024-01-06',
      source: 'وزاؤة الصحة',
    ),
    ArticleModel(
      title: 'عدم تحمل اللاكتوز',
      description:
          'عدم تحمل اللاكتوز يختلف عن حساسية الحليب. تعرّف على أعراضه والبدائل الغذائية المناسبة.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/healthylifestyle/pages/lactoseintolerance.aspx',
      imageUrl: '',
      pubDate: '2024-01-07',
      source: 'وزارة الصحة',
    ),
    ArticleModel(
      title: 'مرض السيلياك - دليل شامل (PDF)',
      description:
          'دليل شامل من وزارة الصحة عن مرض السيلياك والنصائح الغذائية للمصابين.',
      link:
          'https://www.moh.gov.sa/awarenessplateform/HealthyLifestyle/Documents/Celiac-Disease.pdf',
      imageUrl: '',
      pubDate: '2024-01-08',
      source: 'وزارة الصحة',
    ),
  ];

  // Maps article index to its display emoji for UI presentation
  static const List<String> articleEmojis = [
    '🍽️',
    '📋',
    '🚑',
    '🥜',
    '📄',
    '🌾',
    '📄',
    '🥛',
    '📄',
  ];

  // Maps article index to its card background color for UI presentation
  static const List<Color> articleColors = [
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFFEBEE),
    Color(0xFFFFF8E1),
    Color(0xFFF3E5F5),
    Color(0xFFFBE9E7),
    Color(0xFFE0F7FA),
    Color(0xFFF1F8E9),
    Color(0xFFEDE7F6),
  ];
}