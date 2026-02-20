import 'package:flutter/material.dart';
// ✏️ تم إضافة هذين الـ import للربط مع شاشتي النتيجة
import 'safe_result_screen.dart';
import 'unsafe_result_screen.dart';

class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
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
        // ✏️ اختر الحالة اللي تريد تختبرها — فعّل واحدة وعلّق على الثانية

        // ✅ حالة آمن:
        // setState(() {
        //   _isScanning = false;
        //   _scannedBarcode = '7622201765286';
        //   _productName = 'أوريو OREO';
        //   _isSafe = true;
        //   _allergens = [];
        // });

        // ❌ حالة غير آمن:
        setState(() {
          _isScanning = false;
          _scannedBarcode = '6200010102346';
          _productName = 'حليب السعودية بالشوكولاتة';
          _isSafe = false;
          _allergens = ['الحليب'];
        });

        // ✏️ تم إضافة التنقل التلقائي بناءً على نتيجة الفحص
        // آمن → SafeResultScreen | غير آمن → UnsafeResultScreen
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

  void _reset() {
    setState(() {
      _scannedBarcode = null;
      _productName = null;
      _isSafe = null;
      _allergens = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'مسح الباركود',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (_isScanning)
                    const CircularProgressIndicator(color: Colors.white)
                  else if (_scannedBarcode == null)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        _buildScanFrame(),
                      ],
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.blueAccent.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.qr_code, size: 64, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_scannedBarcode == null) ...[
                    Text(
                      'ضع الباركود داخل الإطار',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ✏️ تم تعديل زر الفلاش: يتغير الأيقون والنص واللون حسب الحالة
                        // مفعّل → flash_on أصفر + نص "مضيء"
                        // مغلق  → flash_off رمادي + نص "مغلق"
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isFlashOn = !_isFlashOn;
                            });
                          },
                          child: Column(
                            children: [
                              Icon(
                                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                color: _isFlashOn ? Colors.amber : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isFlashOn ? 'مضيء' : 'مغلق',
                                style: TextStyle(
                                  color: _isFlashOn ? Colors.amber : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _simulateScan,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7CB342),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade600,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildScanResult(),
                  ],
                ],
              ),
            ),
          ),

          _buildBottomNav(),
        ],
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

  Widget _buildScanResult() {
    if (_isSafe == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSafe! ? Icons.check_circle : Icons.cancel,
              color: _isSafe! ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              _isSafe! ? 'المنتج آمن!' : 'المنتج غير آمن!',
              style: TextStyle(
                color: _isSafe! ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('اسم المنتج: $_productName',
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
        if (_allergens != null && _allergens!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('مسببات الحساسية: ${_allergens!.join(', ')}',
              style: const TextStyle(fontSize: 13, color: Colors.orange)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7CB342),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('فحص منتج آخر',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.person_outline, 'الملف الشخصي'),
          _navItem(Icons.list_alt_outlined, 'محتوى نوعي'),
          _navItem(Icons.history, 'السجل'),
          _navItem(Icons.home, 'الرئيسية', isActive: true),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF7CB342) : Colors.grey, size: 22),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF7CB342) : Colors.grey)),
      ],
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