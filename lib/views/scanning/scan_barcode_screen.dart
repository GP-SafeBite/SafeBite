import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // 🔴 added
import '../../services/auth_service.dart'; // 🔴 added
import '../../services/scan_service.dart'; // 🔴 added
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
  bool _barcodeDetected = false; // 🔴 prevents scanning same barcode twice

  // 🔴 added: real camera controller
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose(); // 🔴 added: cleanup camera
    super.dispose();
  }

  // 🔴 changed: now calls real API instead of simulation
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_barcodeDetected || _isScanning) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    setState(() {
      _barcodeDetected = true;
      _isScanning = true;
    });

    // 🔴 stop camera while processing
    await _cameraController.stop();

    // 🔴 get current user
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
        );
      }
      return;
    }

    // 🔴 fetch product from Open Food Facts + check allergens
    final result = await ScanService.fetchProductByBarcode(
      barcode: barcode,
      userId: user['user_id'],
    );

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      setState(() => _barcodeDetected = false);
      await _cameraController.start();
      return;
    }

    final scanData = result.data as ProductScanData;

    // 🔴 changed: pass imageUrl to both result screens
if (scanData.safetyStatus == 'safe') {
  Get.off(() => SafeResultScreen(
        productName: scanData.productName,
        barcode: barcode,
        imageUrl: scanData.imageUrl, // 🔴 added
      ));
} else {
  Get.off(() => UnsafeResultScreen(
        productName: scanData.productName,
        detectedAllergens: scanData.detectedAllergens,
        imageUrl: scanData.imageUrl, // 🔴 added
      ));
}
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
                      onTap: () => Get.back(),
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
                        // 🔴 changed: real camera instead of icon
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: MobileScanner(
                            controller: _cameraController,
                            onDetect: _onBarcodeDetected,
                          ),
                        ),
                        if (_isScanning)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                          )
                        else
                          _buildScanFrame(),
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
                    const SizedBox(width: 48),
                    // 🔴 removed scan button — scanning is automatic
                    // when barcode enters camera frame
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _isScanning
                            ? kGrey900
                            : kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                          // 🔴 toggle real flash
                          _cameraController.toggleTorch();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFlashOn
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color:
                                  _isFlashOn ? Colors.amber : kGrey900,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isFlashOn ? 'مضيء' : 'مغلق',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _isFlashOn
                                    ? Colors.amber
                                    : kGrey900,
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
                    _buildNavItem(
                        Icons.description_outlined, 'محتوى توعوي', false),
                    _buildNavItem(
                        Icons.person_outline, 'الملف الشخصي', false),
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
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
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
    canvas.drawLine(Offset(size.width - cornerSize, 0),
        Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width, cornerSize), paint);
    canvas.drawLine(Offset(0, size.height - cornerSize),
        Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(Offset(size.width - cornerSize, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}