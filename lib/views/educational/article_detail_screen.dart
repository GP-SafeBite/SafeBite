import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/article_model.dart';
import '../../services/articles_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);

  late final WebViewController _webViewController;
  bool _isLoading = true;
  final bool _isPdf = false;

  @override
  void initState() {
    super.initState();

    if (ArticlesService.isPdf(widget.article.link)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ArticlesService.openPdf(widget.article.link);
        if (mounted) Navigator.pop(context);
      });
    } else {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ))
        ..loadRequest(Uri.parse(widget.article.link));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor; // [FIXED Dark Mode]
    final Color kFieldBg = Theme.of(context).cardColor; // [FIXED Dark Mode]

    // Show loading while PDF opens in external browser
    if (ArticlesService.isPdf(widget.article.link)) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: kBackground, // [FIXED Dark Mode]
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'جاري فتح الملف...',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: kGrey900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground, // [FIXED Dark Mode]
        body: SafeArea(
          child: Column(
            children: [
              // ========== HEADER ==========
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kFieldBg, // [FIXED Dark Mode]
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onSurface, // [FIXED Dark Mode]
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.article.source,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ========== ARTICLE TITLE ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.article.title,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface, // [FIXED Dark Mode]
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              const SizedBox(height: 16),

              // ========== WEBVIEW ==========
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}