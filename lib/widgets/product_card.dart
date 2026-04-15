import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  final String productName;
  final String remoteImageUrl;
  final String localImagePath;
  final bool isSafe;
  final String? time;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.productName,
    this.remoteImageUrl = '',
    this.localImagePath = '',
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
              child: _SmartImage(
                remoteUrl: remoteImageUrl,
                localPath: localImagePath,
                isSafe: isSafe,
                height: 120,
              ),
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
}

class _SmartImage extends StatefulWidget {
  final String remoteUrl;
  final String localPath;
  final bool isSafe;
  final double height;

  const _SmartImage({
    required this.remoteUrl,
    required this.localPath,
    required this.isSafe,
    this.height = 120,
  });

  @override
  State<_SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<_SmartImage> {
  // ✅ Try local first if file exists, otherwise try remote
  bool get _hasLocalFile =>
      widget.localPath.isNotEmpty && File(widget.localPath).existsSync();

  @override
  Widget build(BuildContext context) {
    // ✅ Priority 1: local file exists on THIS device → use it directly
    if (_hasLocalFile) {
      return Image.file(
        File(widget.localPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
        errorBuilder: (_, __, ___) => _tryRemote(),
      );
    }
    // ✅ Priority 2: no local file → try remote URL
    return _tryRemote();
  }

  Widget _tryRemote() {
    if (widget.remoteUrl.isNotEmpty) {
      return Image.network(
        widget.remoteUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          // ✅ While loading remote, show local if available
          if (widget.localPath.isNotEmpty) {
            final f = File(widget.localPath);
            if (f.existsSync()) {
              return Image.file(f, fit: BoxFit.cover, width: double.infinity, height: widget.height);
            }
          }
          return _placeholder();
        },
        errorBuilder: (_, __, ___) {
          // ✅ Remote failed → try local as final fallback
          if (widget.localPath.isNotEmpty) {
            final f = File(widget.localPath);
            if (f.existsSync()) {
              return Image.file(f, fit: BoxFit.cover, width: double.infinity, height: widget.height);
            }
          }
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        widget.isSafe ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        size: 40,
        color: widget.isSafe ? const Color(0xFF9CCB7A) : const Color(0xFFD32F2F),
      ),
    );
  }
}