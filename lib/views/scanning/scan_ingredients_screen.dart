import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/scan_controller.dart';
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
      if (cameras.isEmpty) return;
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      print('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) return;
    setState(() => _isScanning = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      await _showProductNameDialog(File(image.path));
    } catch (e) {
      print('Capture error: $e');
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isScanning) return;
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image == null) return;
    setState(() => _isScanning = true);
    await _showProductNameDialog(File(image.path));
  }

  // ✅ Ask user for product name before processing
  Future<void> _showProductNameDialog(File imageFile) async {
    final controller = TextEditingController();

    final productName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('اسم المنتج', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل اسم المنتج (اختياري)', style: GoogleFonts.tajawal(fontSize: 13, color: kGrey900)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'مثال: حليب المراعي',
                  hintStyle: GoogleFonts.tajawal(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                style: GoogleFonts.tajawal(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'منتج من صورة'),
              child: Text('تخطي', style: GoogleFonts.tajawal(color: kGrey900)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim().isEmpty ? 'منتج من صورة' : controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              child: Text('تأكيد', style: GoogleFonts.tajawal(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    await _processImage(imageFile, productName ?? 'منتج من صورة');
  }

  Future<void> _processImage(File imageFile, String productName) async {
    try {
      final scanController = context.read<ScanController>();
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await scanController.analyzeImage(imageFile, userId, productName: productName);

      final result = scanController.result;
      if (result == null) throw Exception("مافي نتيجة");

      final isSafe = result["is_safe"] == true;
      final localImagePath = result["local_image_path"] as String? ?? '';

      if (isSafe) {
        Get.off(() => SafeResultScreen(
              productName: productName,
              ingredients: result["ingredients"] ?? [],
              allergens: result["allergens"] ?? [],
              localImagePath: localImagePath,
            ));
      } else {
        Get.off(() => UnsafeResultScreen(
              productName: productName,
              ingredients: result["ingredients"] ?? [],
              detectedAllergens: List<String>.from(result["allergens"] ?? []),
              localImagePath: localImagePath,
            ));
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحليل الصورة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
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
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFFAF6E9), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('مسح المكونات', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                          Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white))),

                        if (_isScanning)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Colors.white),
                                  const SizedBox(height: 12),
                                  Text('جاري تحليل المكونات بالذكاء الاصطناعي...', style: GoogleFonts.tajawal(color: Colors.white), textAlign: TextAlign.center),
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

              Text('صوّر قائمة المكونات المكتوبة على العبوة',
                style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w500, color: kGrey900),
                textAlign: TextAlign.center),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 48,
                      child: GestureDetector(
                        onTap: _isScanning ? null : _pickFromGallery,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.image_outlined, color: _isScanning ? kGrey900.withOpacity(0.4) : kGrey900, size: 32),
                          const SizedBox(height: 4),
                          Text('الألبوم', style: GoogleFonts.tajawal(fontSize: 12, color: _isScanning ? kGrey900.withOpacity(0.4) : kGrey900)),
                        ]),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isScanning ? null : _captureImage,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(color: _isScanning ? kGrey900 : kPrimary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: GestureDetector(
                        onTap: _toggleFlash,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: _isFlashOn ? Colors.amber : kGrey900, size: 32),
                          const SizedBox(height: 4),
                          Text(_isFlashOn ? 'مضيء' : 'مغلق', style: GoogleFonts.tajawal(fontSize: 12, color: _isFlashOn ? Colors.amber : kGrey900)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}