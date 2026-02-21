// lib/widgets/alternative_product_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlternativeProductCard extends StatelessWidget {
  final String title;
  final String imagePathOrUrl;
  final VoidCallback? onTap;

  const AlternativeProductCard({
    super.key,
    required this.title,
    required this.imagePathOrUrl,
    this.onTap,
  });

  static const Color kCardBg  = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // ===== صورة المنتج (يسار) =====
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: imagePathOrUrl.startsWith('http')
                    ? Image.network(
                        imagePathOrUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : Image.asset(
                        imagePathOrUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
              ),
            ),
            // ===== اسم المنتج (يمين) =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEDE8D8),
      child: const Icon(Icons.image_outlined, color: Color(0xFFB3B3B3), size: 36),
    );
  }
}