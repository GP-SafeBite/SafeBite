// AlternativeProductCard - Display a single safe alternative product with image and title

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

  static final _titleStyle = GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    final Color kCardBg = Theme.of(context).cardColor;

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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                // Load from network URL or local asset depending on path format
                child: imagePathOrUrl.startsWith('http')
                    ? Image.network(
                        imagePathOrUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 180,
                        cacheHeight: 180,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : Image.asset(
                        imagePathOrUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: _titleStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
      child: const Icon(Icons.image_outlined,
          color: Color(0xFFB3B3B3), size: 36),
    );
  }
}