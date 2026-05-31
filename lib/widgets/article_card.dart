import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArticleCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback? onTap;

  const ArticleCard({
    super.key,
    required this.title,
    this.imageUrl = '',
    this.onTap,
  });

  // [PERF] Font constant — created once
  static final _titleStyle = GoogleFonts.tajawal(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final Color kCardBg = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              color: Colors.white,
              child: imageUrl.isEmpty
                  ? const Center(
                      child: Icon(Icons.image_outlined,
                          size: 40, color: Color(0xFFD1D1D1)))
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      // [PERF] Limit decoded image size — card is 120px tall
                      cacheWidth: 800,
                      cacheHeight: 240,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_outlined,
                            size: 40, color: Color(0xFFD1D1D1)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: _titleStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}