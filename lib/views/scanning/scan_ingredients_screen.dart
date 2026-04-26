import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/scan_service.dart';
import '../../services/camera_service.dart';
import 'safe_result_screen.dart';
import 'unsafe_result_screen.dart';

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
      _cameraController = await CameraService.getController();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      print('Camera error: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isScanning) return;
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
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return;
    setState(() => _isScanning = true);
    await _showProductNameDialog(File(image.path));
  }

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
              Text('أدخل اسم المنتج (اختياري)',
                  style: GoogleFonts.tajawal(fontSize: 13, color: kGrey900)),
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
              onPressed: () => Navigator.pop(
                context,
                controller.text.trim().isEmpty ? 'منتج من صورة' : controller.text.trim(),
              ),
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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
          );
        }
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final scanResult = await ScanService.scanFromImage(
        imageBytes: imageBytes,
        userId: userId,
        productName: productName,
      );

      if (!scanResult.success || scanResult.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(scanResult.message)),
          );
        }
        return;
      }

      final ProductScanData data = scanResult.data as ProductScanData;

      if (!mounted) return;

      if (data.safetyStatus == 'safe') {
        Get.off(() => SafeResultScreen(
              productName: data.productName,
              ingredients: data.ingredients,
              allergens: data.detectedAllergens,
              localImagePath: data.localImagePath ?? '',
              remoteImageUrl: data.remoteImageUrl ?? '',
            ));
      } else {
        Get.off(() => UnsafeResultScreen(
              productName: data.productName,
              ingredients: data.ingredients,
              detectedAllergens: data.detectedAllergens,
              detectedAllergenTypes: data.detectedAllergenTypes,
              llmSuggestedAlternatives: data.llmSuggestedAlternatives,
              llmRawAlternatives: data.llmRawAlternatives,
              productTypeAr: data.productTypeAr,
              traceWarnings: data.traceWarnings,
              localImagePath: data.localImagePath ?? '',
              remoteImageUrl: data.remoteImageUrl ?? '',
              savedAlternatives: data.mergedAlternatives.isNotEmpty ? data.mergedAlternatives : null,
            ));
      }
    } catch (e) {
      print("🔥 _processImage ERROR: $e");
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
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor; // [FIXED Dark Mode]
    final Color kCardBg = Theme.of(context).cardColor; // [FIXED Dark Mode]

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground, // [FIXED Dark Mode]
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kCardBg, // [FIXED Dark Mode]
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onSurface, size: 20), // [FIXED Dark Mode]
                      ),
                    ),
                    const Spacer(),
                    Text('مسح المكونات',
                        style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w700)),
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
                                  Text('جاري تحليل المكونات...',
                                      style: GoogleFonts.tajawal(color: Colors.white),
                                      textAlign: TextAlign.center),
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
                  style: GoogleFonts.tajawal(fontSize: 14, color: kGrey900),
                  textAlign: TextAlign.center),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _isScanning ? null : _pickFromGallery,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined,
                              color: _isScanning ? kGrey900.withOpacity(0.4) : kGrey900, size: 32),
                          const SizedBox(height: 4),
                          Text('الألبوم',
                              style: GoogleFonts.tajawal(fontSize: 12,
                                  color: _isScanning ? kGrey900.withOpacity(0.4) : kGrey900)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _isScanning ? null : _captureImage,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: _isScanning ? kGrey900 : kPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: _isFlashOn ? Colors.amber : kGrey900, size: 32),
                          const SizedBox(height: 4),
                          Text(_isFlashOn ? 'مضيء' : 'مغلق',
                              style: GoogleFonts.tajawal(fontSize: 12,
                                  color: _isFlashOn ? Colors.amber : kGrey900)),
                        ],
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