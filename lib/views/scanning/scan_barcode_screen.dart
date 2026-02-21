import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'safe_result_screen.dart';
import 'unsafe_result_screen.dart';

class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);

  bool _isFlashOn = false;
  bool _isScanning = false;
  String? _scannedBarcode;
  String? _productName;
  bool? _isSafe;
  List<String>? _allergens;

  void _simulateScan() {
    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // ❌ حالة غير آمن:
        setState(() {
          _isScanning = false;
          _scannedBarcode = '6200010102346';
          _productName = 'حليب السعودية بالشوكولاتة';
          _isSafe = false;
          _allergens = ['الحليب'];
        });

        if (_isSafe == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SafeResultScreen(productName: _productName!),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UnsafeResultScreen(
                productName: _productName!,
                detectedAllergens: _allergens ?? [],
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ========== HEADER ==========
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF6E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'مسح الباركود',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ========== CAMERA VIEW ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isScanning)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.camera_alt_outlined,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              _buildScanFrame(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'ضع الباركود داخل الإطار',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kGrey900,
                ),
              ),

              const Spacer(),

              // ========== الأزرار ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 48,
                      child: GestureDetector(
                        onTap: () {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: kGrey900,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _simulateScan,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: _isFlashOn ? Colors.amber : kGrey900,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isFlashOn ? 'مضيء' : 'مغلق',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _isFlashOn ? Colors.amber : kGrey900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ========== BOTTOM NAVIGATION ==========
              Container(
                height: 70,
                decoration: const BoxDecoration(
                  color: kBackground,
                ),
                child: Row(
                  children: [
                    _buildNavItem(Icons.home, 'الرئيسية', true),
                    _buildNavItem(Icons.history, 'السجل', false),
                    _buildNavItem(Icons.description_outlined, 'محتوى توعوي', false),
                    _buildNavItem(Icons.person_outline, 'الملف الشخصي', false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return SizedBox(
      width: 200,
      height: 100,
      child: CustomPaint(painter: _ScanFramePainter()),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? kPrimary : kGrey900,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kPrimary : kGrey900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const cornerSize = 20.0;
    canvas.drawLine(Offset(0, cornerSize), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerSize, 0), paint);
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}