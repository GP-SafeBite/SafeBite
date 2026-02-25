import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart'; // 🔴 added
import '../../services/scan_service.dart'; // 🔴 added
import 'safe_result_screen.dart';
import 'unsafe_result_screen.dart';

class ScanIngredientsScreen extends StatefulWidget {
  const ScanIngredientsScreen({super.key});

  @override
  State<ScanIngredientsScreen> createState() =>
      _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState
    extends State<ScanIngredientsScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);

  bool _isFlashOn = false;
  bool _isScanning = false;

  // 🔴 added: text controller for manual ingredients input
  final TextEditingController _ingredientsController =
      TextEditingController();
  bool _showTextInput = false; // 🔴 shows text field after photo

  @override
  void dispose() {
    _ingredientsController.dispose(); // 🔴 cleanup
    super.dispose();
  }

  // 🔴 changed: shows text input after tapping camera button
  // temporary solution until OCR is implemented
  void _onCameraTap() {
    setState(() {
      _showTextInput = true;
    });
  }

  // 🔴 changed: checks typed ingredients against user allergies
  Future<void> _checkIngredients() async {
    final text = _ingredientsController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إدخال المكونات أولاً')),
      );
      return;
    }

    setState(() => _isScanning = true);

    // 🔴 get current user
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isScanning = false);
      return;
    }

    // 🔴 check ingredients text against user allergies
    final result = await ScanService.checkIngredientsText(
      ingredientsText: text,
      userId: user['user_id'],
    );

    setState(() => _isScanning = false);
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    final scanData = result.data as ProductScanData;

    // 🔴 navigate based on result
    if (scanData.safetyStatus == 'safe') {
      Get.off(() => SafeResultScreen(
            productName: scanData.productName,
          ));
    } else {
      Get.off(() => UnsafeResultScreen(
            productName: scanData.productName,
            detectedAllergens: scanData.detectedAllergens,
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
                      'مسح المكونات',
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
                          const CircularProgressIndicator(
                              color: Colors.white)
                        else
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 64,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔴 changed: shows text field after camera tap
              if (_showTextInput) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _ingredientsController,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اكتب المكونات هنا...',
                      hintStyle: GoogleFonts.tajawal(color: kGrey900),
                      filled: true,
                      fillColor: const Color(0xFFFAF6E9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.tajawal(),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checkIngredients,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        'تحقق من المكونات',
                        style: GoogleFonts.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'صوّر قائمة المكونات المكتوبة على العبوة',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kGrey900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // ========== الأزرار ==========
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    GestureDetector(
                      onTap: _onCameraTap, // 🔴 shows text input
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
                              _isFlashOn
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: _isFlashOn
                                  ? Colors.amber
                                  : kGrey900,
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
                    _buildNavItem(Icons.description_outlined,
                        'محتوى توعوي', false),
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