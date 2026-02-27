import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';

// Every function returns this — frontend always knows what happened
class AuthResult {
  final bool success;
  final String message;
  final dynamic data;

  AuthResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class AuthService {
  static final _supabase = Supabase.instance.client;

  // 🔴 added: global debounce flags to prevent duplicate API calls
  static bool _isRegistering = false;
  static bool _isVerifying = false;
  static bool _isLoggingIn = false;
  static bool _isSendingOTP = false;

  // ──────────────────────────────────────────────
  // REGISTER
  // Creates account in Supabase Auth
  // Trigger automatically creates row in User table
  // Supabase sends 6-digit OTP to email
  // ──────────────────────────────────────────────
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // 🔴 added: prevent duplicate signUp() calls which invalidate OTP
    if (_isRegistering) {
      return AuthResult(success: false, message: 'جاري المعالجة، انتظر لحظة...');
    }
    _isRegistering = true;

    try {
      if (name.trim().isEmpty) {
        return AuthResult(success: false, message: 'Please enter your name');
      }
      if (!email.contains('@') || !email.contains('.')) {
        return AuthResult(success: false, message: 'Please enter a valid email');
      }
      if (password.length < 8) {
        return AuthResult(
            success: false, message: 'Password must be at least 8 characters');
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        return AuthResult(
            success: false, message: 'Registration failed. Please try again.');
      }

      // Do NOT save to SQLite yet — wait until OTP is verified
      return AuthResult(
        success: true,
        message: 'A 6-digit verification code has been sent to $email',
        data: {'email': email, 'name': name},
      );

    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return AuthResult(
            success: false,
            message: 'This email is already registered. Please login.');
      }
      return AuthResult(success: false, message: e.message);

    } catch (e) {
      return AuthResult(
          success: false,
          message: 'Connection error. Please check your internet.');

    } finally {
      // 🔴 added: always release the lock even if an error occurs
      _isRegistering = false;
    }
  }

  // ──────────────────────────────────────────────
  // VERIFY OTP (signup)
  // User enters the 6-digit code from email
  // Only after this succeeds do we save to SQLite
  // ──────────────────────────────────────────────
  static Future<AuthResult> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    // 🔴 added: prevent double-tap on verify button sending two verify requests
    if (_isVerifying) {
      return AuthResult(success: false, message: 'جاري التحقق...');
    }
    _isVerifying = true;

    try {
      if (otpCode.trim().length != 6) {
        return AuthResult(success: false, message: 'Please enter all 6 digits');
      }

      // 🔴 fixed: was OtpType.email — must be OtpType.signup to match signUp() flow
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: OtpType.signup,
      );

      if (response.user == null) {
        return AuthResult(
            success: false,
            message: 'Invalid or expired code. Please try again.');
      }

      final user = response.user!;
      final name = user.userMetadata?['name'] ?? '';

      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
      );

      return AuthResult(
        success: true,
        message: 'Account verified successfully',
        data: {'userId': user.id, 'email': email, 'name': name},
      );

    } on AuthException catch (e) {
      // 🔴 note: "token has expired or is invalid" from Supabase logs maps here
      if (e.message.contains('expired') || e.message.contains('invalid')) {
        return AuthResult(
            success: false,
            message: 'Code has expired. Please request a new one.');
      }
      return AuthResult(success: false, message: 'Invalid code. Please try again.');

    } catch (e) {
      return AuthResult(
          success: false,
          message: 'Connection error. Please check your internet.');

    } finally {
      // 🔴 added: always release the lock
      _isVerifying = false;
    }
  }

  // ──────────────────────────────────────────────
  // RESEND OTP (signup)
  // User didn't receive code or it expired
  // ──────────────────────────────────────────────
  static Future<AuthResult> resendOTP({
    required String email,
  }) async {
    try {
      // 🔴 confirmed: OtpType.signup matches verifyOTP above — correct
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return AuthResult(
          success: true, message: 'A new code has been sent to $email');

    } catch (e) {
      return AuthResult(
          success: false, message: 'Could not resend code. Please try again.');
    }
  }

  // ──────────────────────────────────────────────
  // LOGIN (email + password)
  // ──────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // 🔴 added: prevent duplicate login calls
    if (_isLoggingIn) {
      return AuthResult(success: false, message: 'جاري تسجيل الدخول...');
    }
    _isLoggingIn = true;

    try {
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult(
            success: false,
            message: 'Please enter your email and password');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult(success: false, message: 'Login failed');
      }

      final user = response.user!;
      final name = user.userMetadata?['name'] ?? '';

      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
      );

      return AuthResult(
        success: true,
        message: 'Welcome back!',
        data: {'userId': user.id, 'email': email, 'name': name},
      );

    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return AuthResult(success: false, message: 'Wrong email or password');
      }
      if (e.message.contains('Email not confirmed')) {
        return AuthResult(
          success: false,
          message: 'Please verify your email first',
          data: {'needsVerification': true, 'email': email},
        );
      }
      return AuthResult(success: false, message: e.message);

    } catch (e) {
      return AuthResult(
          success: false,
          message: 'Connection error. Please check your internet.');

    } finally {
      // 🔴 added: always release the lock
      _isLoggingIn = false;
    }
  }

  // ──────────────────────────────────────────────
  // SEND LOGIN OTP (passwordless login)
  // ──────────────────────────────────────────────
  static Future<AuthResult> sendLoginOTP({
    required String email,
  }) async {
    // 🔴 added: prevent duplicate OTP send calls
    if (_isSendingOTP) {
      return AuthResult(success: false, message: 'جاري الإرسال...');
    }
    _isSendingOTP = true;

    try {
      if (email.trim().isEmpty) {
        return AuthResult(
            success: false, message: 'الرجاء إدخال البريد الإلكتروني');
      }

      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // don't create new account
      );

      return AuthResult(
          success: true, message: 'تم إرسال رمز التحقق إلى $email');

    } on AuthException catch (e) {
      if (e.message.contains('not found')) {
        return AuthResult(
            success: false, message: 'البريد الإلكتروني غير مسجل');
      }
      return AuthResult(success: false, message: e.message);

    } catch (e) {
      return AuthResult(
          success: false, message: 'خطأ في الاتصال. تحقق من الإنترنت');

    } finally {
      // 🔴 added: always release the lock
      _isSendingOTP = false;
    }
  }

  // ──────────────────────────────────────────────
  // VERIFY LOGIN OTP (passwordless login)
  // ──────────────────────────────────────────────
  static Future<AuthResult> verifyLoginOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      if (otpCode.trim().length != 6) {
        return AuthResult(
            success: false, message: 'الرجاء إدخال الرمز كاملاً');
      }

      // 🔴 confirmed: OtpType.email is correct for signInWithOtp() flow
      // (magiclink also works but email is more explicit for 6-digit OTP)
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: OtpType.email,
      );

      if (response.user == null) {
        return AuthResult(
            success: false, message: 'رمز غير صحيح أو منتهي الصلاحية');
      }

      final user = response.user!;
      final name = user.userMetadata?['name'] ?? '';

      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
      );

      return AuthResult(
        success: true,
        message: 'تم تسجيل الدخول بنجاح',
        data: {'userId': user.id, 'email': email, 'name': name},
      );

    } on AuthException catch (e) {
      return AuthResult(success: false, message: 'رمز غير صحيح. حاول مجدداً');

    } catch (e) {
      return AuthResult(
          success: false, message: 'خطأ في الاتصال. تحقق من الإنترنت');
    }
  }

  // ──────────────────────────────────────────────
  // LOGOUT
  // Clears Supabase session + SQLite local data
  // ──────────────────────────────────────────────
  static Future<AuthResult> logout() async {
    try {
      await _supabase.auth.signOut();
      await LocalDB.clearUserSession(); // ✅ Only clears user session, keeps scan history
      return AuthResult(success: true, message: 'Logged out successfully');

    } catch (e) {
      return AuthResult(success: false, message: 'Logout failed');
    }
  }

  // ──────────────────────────────────────────────
  // IS LOGGED IN
  // Used by splash screen to decide where to go
  // ──────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    if (session != null) return true;
    final localUser = await LocalDB.getUser();
    return localUser != null;
  }

  // ──────────────────────────────────────────────
  // GET CURRENT USER
  // ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await LocalDB.getUser();
  }

  // 🔴 added: update user name in Supabase and SQLite
static Future<bool> updateUserName({required String newName}) async {
  try {
    final user = await getCurrentUser();
    if (user == null) return false;

    // 🔴 update Supabase User table
    await _supabase
        .from('User')
        .update({'name': newName})
        .eq('user_id', user['user_id']);

    // 🔴 update SQLite
    final db = await LocalDB.getDatabase();
    await db.update(
      'current_user',
      {'name': newName},
      where: 'user_id = ?',
      whereArgs: [user['user_id']],
    );

    return true;
  } catch (e) {
    print('❌ Update name error: $e');
    return false;
  }
}
}