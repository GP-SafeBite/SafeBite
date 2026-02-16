// lib/widgets/article_card.dart
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

  static const Color kCardBg = Color(0xFFFAF6E9);

  @override
  Widget build(BuildContext context) {
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
            // صورة المقال (فوق)
            Container(
              width: double.infinity,
              height: 120,
              color: Colors.white,
              child: imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: Color(0xFFD1D1D1),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Color(0xFFD1D1D1),
                          ),
                        );
                      },
                    ),
            ),

            // عنوان المقال (تحت)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                textAlign: TextAlign.right, // ✅ من اليمين
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}