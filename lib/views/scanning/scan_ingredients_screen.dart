import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'safe_result_screen.dart';
import 'unsafe_result_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/scan_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanIngredientsScreen extends StatefulWidget {
  const ScanIngredientsScreen({super.key});

  @override
  State<ScanIngredientsScreen> createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);

  bool _isFlashOn = false;
  bool _isScanning = false;
  bool _isCameraReady = false;

  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      print('عدد الكاميرات: ${cameras.length}');

      if (cameras.isEmpty) {
        print('ما في كاميرات!');
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      print('الكاميرا: ${backCamera.name}');

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      print('الكاميرا جاهزة ✅');

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      print('خطأ في الكاميرا: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final XFile image = await _cameraController!.takePicture();
      await _processImage(File(image.path));
    } catch (e) {
      print('خطأ في التقاط الصورة: $e');
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء التقاط الصورة')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) return;

    setState(() => _isScanning = true);
    await _processImage(File(image.path));
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final controller = context.read<ScanController>();
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await controller.analyzeImage(imageFile, userId);

      final result = controller.result;

      if (result == null) {
        throw Exception("مافي نتيجة");
      }

      final isSafe = result["is_safe"] == true;

      if (isSafe) {
        Get.off(() => SafeResultScreen(
              productName: "منتج من صورة",
              ingredients: result["ingredients"],
              allergens: result["allergens"],
            ));
      } else {
        Get.off(() => UnsafeResultScreen(
              productName: "منتج من صورة",
              ingredients: result["ingredients"],
              detectedAllergens: List<String>.from(result["allergens"]),
            ));
      }
    } catch (e) {
      print("🔥 Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحليل الصورة')),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() => _isFlashOn = !_isFlashOn);
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ [Added] Dynamic colors from Theme
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kCardBg = Theme.of(context).cardColor;

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
                        decoration: BoxDecoration(
                          color: kCardBg, // ✅ [Added]
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'مسح المكونات',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width - 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isCameraReady)
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!.value.previewSize!.height,
                                height: _cameraController!.value.previewSize!.width,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),

                        if (_isScanning)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Colors.white),
                                  const SizedBox(height: 12),
                                  Text(
                                    'جاري تحليل المكونات...',
                                    style: GoogleFonts.tajawal(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
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
                        onTap: _isScanning ? null : _pickFromGallery,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: _isScanning ? kGrey900.withOpacity(0.4) : kGrey900,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الألبوم',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: _isScanning ? kGrey900.withOpacity(0.4) : kGrey900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: _isScanning ? null : _captureImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isScanning ? kGrey900 : kPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 48,
                      child: GestureDetector(
                        onTap: _toggleFlash,
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
                decoration: BoxDecoration(color: kBackground), // ✅ [Added]
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
            Icon(icon, color: isActive ? kPrimary : kGrey900, size: 26),
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