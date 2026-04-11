import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final String imageUrl;       // remote URL (Supabase Storage)
  final String? localImagePath; // local file path
  final bool isSafe;
  final String? time;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.productName,
    this.imageUrl = '',
    this.localImagePath,
    required this.isSafe,
    this.time,
    this.onTap,
  });

  static const Color kCardBg = Color(0xFFFAF6E9);
  static const Color kRed = Color(0xFFD32F2F);
  static const Color kGreen = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              color: Colors.white,
              child: _buildImage(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName.isNotEmpty ? productName : 'فحص مكونات',
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isSafe ? Icons.check_circle : Icons.cancel, size: 20, color: isSafe ? kGreen : kRed),
                            const SizedBox(width: 6),
                            Text(isSafe ? 'آمن' : 'غير آمن', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: isSafe ? kGreen : kRed)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(width: 8),
                    Text(time!, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w500, color: kGrey900)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // ✅ Priority 1: local file (fast, offline)
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      final file = File(localImagePath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
        errorBuilder: (_, __, ___) => _tryRemoteOrPlaceholder(),
      );
    }
    return _tryRemoteOrPlaceholder();
  }

  // ✅ Priority 2: remote URL (works on any device/session)
  Widget _tryRemoteOrPlaceholder() {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: isSafe ? kGreen : kRed));
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        isSafe ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        size: 40,
        color: isSafe ? kGreen : kRed,
      ),
    );
  }
}