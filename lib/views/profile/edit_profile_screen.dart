import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color kPrimary = Color(0xFF9CCB7A);
  static const Color kGrey900 = Color(0xFF818898);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _currentPhotoUrl = '';
  File? _pendingPhotoFile;
  bool _deletePhoto = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _nameController.text  = user['name']      ?? '';
        _emailController.text = user['email']     ?? '';
        _currentPhotoUrl      = user['photo_url'] ?? '';
        _userId               = user['user_id'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() {
      _pendingPhotoFile = File(picked.path);
      _deletePhoto = false;
    });
  }

  void _removePhoto() {
    setState(() {
      _pendingPhotoFile = null;
      _deletePhoto = true;
    });
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الاسم')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final nameSuccess = await AuthService.updateUserName(newName: newName);

    if (_pendingPhotoFile != null && _userId != null) {
      await AuthService.uploadProfilePhoto(
        userId: _userId!,
        filePath: _pendingPhotoFile!.path,
      );
    } else if (_deletePhoto && _userId != null) {
      await AuthService.deleteProfilePhoto(userId: _userId!);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (nameSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
      );
      Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل حفظ التغييرات')),
      );
    }
  }

  Widget _buildAvatar() {
    if (_deletePhoto) {
      return const Icon(Icons.person, size: 60, color: Colors.white);
    }
    if (_pendingPhotoFile != null) {
      return ClipOval(
        child: Image.file(
          _pendingPhotoFile!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }
    if (_currentPhotoUrl.isNotEmpty) {
      final url = '$_currentPhotoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return ClipOval(
        child: Image.network(
          url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 60, color: Colors.white),
        ),
      );
    }
    return const Icon(Icons.person, size: 60, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ [Added] Dynamic colors from Theme
    final Color kBackground = Theme.of(context).scaffoldBackgroundColor;
    final Color kFieldBg = Theme.of(context).cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground, // ✅ [Added]
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // ========== HEADER ==========
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Get.back(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: kFieldBg, // ✅ [Added]
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_back, size: 20),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'تعديل الملف الشخصي',
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

                            const SizedBox(height: 40),

                            // ========== صورة البروفايل ==========
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFB3D9E8),
                                  ),
                                  child: _buildAvatar(),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickPhoto,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: kPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                                if (_currentPhotoUrl.isNotEmpty ||
                                    _pendingPhotoFile != null)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: GestureDetector(
                                      onTap: _removePhoto,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            if (_pendingPhotoFile != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'صورة جديدة — ستُحفظ عند الضغط على حفظ',
                                  style: GoogleFonts.tajawal(
                                      fontSize: 12, color: kGrey900),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            if (_deletePhoto)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'ستُحذف الصورة عند الضغط على حفظ',
                                  style: GoogleFonts.tajawal(
                                      fontSize: 12, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 40),

                            // ========== الاسم الكامل ==========
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الاسم الكامل',
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: kFieldBg, // ✅ [Added]
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _nameController,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.tajawal(
                                    fontSize: 15, color: kGrey900),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ========== البريد الالكتروني ==========
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'البريد الالكتروني',
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface, // ✅ [Added]
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _emailController,
                                textAlign: TextAlign.right,
                                enabled: false,
                                style: GoogleFonts.tajawal(
                                    fontSize: 15, color: kGrey900),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ========== زر حفظ التغييرات ==========
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: _isSaving
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton(
                              text: 'حفظ التغييرات',
                              onTap: _saveChanges,
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}