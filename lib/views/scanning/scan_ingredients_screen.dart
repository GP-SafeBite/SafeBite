import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'safe_result_screen.dart';
import 'unsafe_result_screen.dart';

class ScanIngredientsScreen extends StatefulWidget {
  const ScanIngredientsScreen({super.key});

  @override
  State<ScanIngredientsScreen> createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kGrey900 = Color(0xFF818898);

  bool _isFlashOn = false;
  bool _isScanning = false;

  void _simulateScan() {
    setState(() {
      _isScanning = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SafeResultScreen(
              productName: 'منتج تجريبي',
            ),
          ),
        );
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
                          const CircularProgressIndicator(color: Colors.white)
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
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