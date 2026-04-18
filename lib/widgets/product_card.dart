import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final String imageUrl;
  final bool isSafe;
  final String? time;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.productName,
    this.imageUrl = '',
    required this.isSafe,
    this.time,
    this.onTap,
  });

  static const Color kRed   = Color(0xFFD32F2F);
  static const Color kGreen = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);

  @override
  Widget build(BuildContext context) {
    // ✅ [Added] Dynamic card color from Theme
    final Color kCardBg = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardBg, // ✅ [Added]
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // صورة المنتج (فوق)
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

            // تفاصيل المنتج (تحت)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المنتج والبادج (على اليسار)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المنتج
                        Text(
                          productName,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Badge آمن/غير آمن
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              isSafe ? Icons.check_circle : Icons.cancel,
                              size: 20,
                              color: isSafe ? kGreen : kRed,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSafe ? 'آمن' : 'غير آمن',
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSafe ? kGreen : kRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // الوقت على اليمين
                  if (time != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      time!,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kGrey900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}