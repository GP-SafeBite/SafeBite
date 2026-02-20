import 'package:flutter/material.dart';

class ScanIngredientsScreen extends StatefulWidget {
  const ScanIngredientsScreen({super.key});

  @override
  State<ScanIngredientsScreen> createState() => _ScanIngredientsScreenState();
}

class _ScanIngredientsScreenState extends State<ScanIngredientsScreen> {
  bool _isFlashOn = false;
  bool _isScanning = false;
  bool _hasScanned = false;

  void _simulateScan() {
    setState(() {
      _isScanning = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _hasScanned = true;
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _hasScanned = false;
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
          'مسح المكونات',
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
          // Camera viewfinder
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
                  else if (!_hasScanned)
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.white.withOpacity(0.7),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.white10,
                        child: const Center(
                          child: Icon(Icons.document_scanner, size: 64, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_hasScanned) ...[
                    Text(
                      'صوّر قائمة المكونات المكتوبة على العبوة',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ✏️ زر الفلاش: يتغير الأيقون والنص واللون حسب الحالة
                        // مفعّل → flash_on أصفر + نص "مضيء"
                        // مغلق  → flash_off رمادي + نص "مغلق"
                        GestureDetector(
                          onTap: () => setState(() => _isFlashOn = !_isFlashOn),
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
                    // Ingredients scanned result navigation
                    Text(
                      'تم مسح المكونات بنجاح',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to result screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7CB342),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'عرض النتائج',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7CB342)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'مسح مجدداً',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF7CB342),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF7CB342) : Colors.grey,
          ),
        ),
      ],
    );
  }
}