import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import 'login_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isLoginMode;

  const VerificationScreen({
    super.key,
    required this.email,
    this.isLoginMode = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color _bg = Color(0xFFFFFDF6);
  static const Color _primary = Color(0xFFA0C878);
  static const Color _otpFill = Color(0xFFFAF6E9);
  static const Color _muted = Color(0xFF7C8797);
  static const Color _overlay = Color(0x66222222);

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection =
          TextSelection.fromPosition(const TextPosition(offset: 1));
    }
    if (_controllers[index].text.isNotEmpty && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    if (_controllers[index].text.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0) return;

    final result = widget.isLoginMode
        ? await AuthService.sendLoginOTP(email: widget.email)
        : await AuthService.resendOTP(email: widget.email);

    _startTimer();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _verifyCode() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فضلاً أدخل الرمز كاملًا')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = widget.isLoginMode
        ? await AuthService.verifyLoginOTP(
            email: widget.email,
            otpCode: _otpCode,
          )
        : await AuthService.verifyOTP(
            email: widget.email,
            otpCode: _otpCode,
          );

    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;

    if (result.success) {
      if (widget.isLoginMode) {
        Get.offAll(() => const HomeScreen());
      } else {
        _showSuccessDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: _overlay,
      builder: (_) {
        return Dialog(
          backgroundColor: _bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F2EC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2CC5A5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'تم تأكيد البريد الإلكتروني',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'تم إنشاء حسابك بنجاح\nيمكنك الآن الدخول',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      height: 1.5,
                      color: _muted,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'تسجيل الدخول الآن',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.offAll(() => const ProfileSetupScreen());
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _otpBox(int index) {
    bool isLocked() {
      final firstEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
      return firstEmpty != -1 && firstEmpty != index;
    }

    return GestureDetector(
      onTap: () {
        if (isLocked()) {
          final firstEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
          _nodes[firstEmpty].requestFocus();
        }
      },
      child: AbsorbPointer(
        absorbing: isLocked(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: TextField(
            controller: _controllers[index],
            focusNode: _nodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: _otpFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => _onOtpChanged(index, v),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 90),
                const Text(
                  'أدخل رمز التحقق',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 55),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, _otpBox),
                  ),
                ),
                const SizedBox(height: 26),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'يمكنك إعادة إرسال الرمز خلال ',
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                      TextSpan(
                        text: '$_secondsRemaining',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' ثانية',
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _resendCode,
                  child: const Text(
                    'إعادة إرسال الرمز',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'التسجيل',
                    onTap: _verifyCode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}