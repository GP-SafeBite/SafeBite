import 'package:flutter/material.dart';
import '../../widgets/auth_input_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const Color kPrimary = Color(0xFFA0C878);
  static const Color kBackground = Color(0xFFFFFDF6);
  static const Color kFieldBg = Color(0xFFFAF6E9);
  static const Color kGrey900 = Color(0xFF818898);
  static const Color kGrey400 = Color(0xFFB3B3B3);
  static const Color kGrey300 = Color(0xFFD1D1D1);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                const Text(
                  'إنشاء حساب جديد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'الاسم الكامل',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                const AuthInputField(
                  hint: 'أحمد',
                  fieldBg: kFieldBg,
                  grey900: kGrey900,
                  grey300: kGrey300,
                ),

                const SizedBox(height: 20),

                const Text(
                  'البريد الإلكتروني',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                const AuthInputField(
                  hint: 'aaronramsdale@gmail.com',
                  fieldBg: kFieldBg,
                  grey900: kGrey900,
                  grey300: kGrey300,
                ),

                const SizedBox(height: 20),

                const Text(
                  'كلمة المرور',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kGrey900,
                  ),
                ),
                const SizedBox(height: 8),
                const AuthInputField(
                  hint: '************',
                  isPassword: true,
                  fieldBg: kFieldBg,
                  grey900: kGrey900,
                  grey300: kGrey300,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ✅ يرجع للّوقن
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kGrey400,
                      ),
                      children: [
                        TextSpan(text: 'لديك حساب بالفعل؟ '),
                        TextSpan(
                          text: 'سجّل دخولك',
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
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
