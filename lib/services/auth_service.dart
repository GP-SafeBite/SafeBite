import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_db.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  static bool _isRegistering = false;
  static bool _isVerifying = false;
  static bool _isLoggingIn = false;
  static bool _isSendingOTP = false;

  // ──────────────────────────────────────────────
  // REGISTER
  // ──────────────────────────────────────────────
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
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
      _isRegistering = false;
    }
  }

  // ──────────────────────────────────────────────
  // VERIFY OTP (signup)
  // ──────────────────────────────────────────────
  static Future<AuthResult> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    if (_isVerifying) {
      return AuthResult(success: false, message: 'جاري التحقق...');
    }
    _isVerifying = true;

    try {
      if (otpCode.trim().length != 6) {
        return AuthResult(success: false, message: 'Please enter all 6 digits');
      }

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

      String name = '';
      String photoUrl = '';
      try {
        final userData = await _supabase
            .from('User')
            .select('name, photo_url')
            .eq('user_id', user.id)
            .single();
        name = userData['name'] ?? user.userMetadata?['name'] ?? '';
        photoUrl = userData['photo_url'] ?? '';
      } catch (e) {
        name = user.userMetadata?['name'] ?? '';
      }

      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );

      return AuthResult(
        success: true,
        message: 'Account verified successfully',
        data: {'userId': user.id, 'email': email, 'name': name},
      );

    } on AuthException catch (e) {
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
      _isVerifying = false;
    }
  }

  // ──────────────────────────────────────────────
  // RESEND OTP (signup)
  // ──────────────────────────────────────────────
  static Future<AuthResult> resendOTP({
    required String email,
  }) async {
    try {
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

      String name = '';
      String photoUrl = '';
      try {
        final userData = await _supabase
            .from('User')
            .select('name, photo_url')
            .eq('user_id', user.id)
            .single();
        name = userData['name'] ?? user.userMetadata?['name'] ?? '';
        photoUrl = userData['photo_url'] ?? '';
      } catch (e) {
        name = user.userMetadata?['name'] ?? '';
      }

      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );

      try {
        final allergies = await _supabase
            .from('userallergy')
            .select('allergy_id')
            .eq('user_id', user.id);
        await LocalDB.saveUserAllergies(
          userId: user.id,
          allergyIds: (allergies as List)
              .map<int>((a) => a['allergy_id'] as int)
              .toList(),
        );
      } catch (e) {
        print('⚠️ Could not reload allergies: $e');
      }

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
      _isLoggingIn = false;
    }
  }

  // ──────────────────────────────────────────────
  // SEND LOGIN OTP (passwordless login)
  // ──────────────────────────────────────────────
  static Future<AuthResult> sendLoginOTP({
    required String email,
  }) async {
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
        shouldCreateUser: false,
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

      String name = '';
      String photoUrl = '';
      try {
        final userData = await _supabase
            .from('User')
            .select('name, photo_url')
            .eq('user_id', user.id)
            .single();
        name = userData['name'] ?? user.userMetadata?['name'] ?? '';
        photoUrl = userData['photo_url'] ?? '';
      } catch (e) {
        name = user.userMetadata?['name'] ?? '';
      }

      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );

      try {
        final allergies = await _supabase
            .from('userallergy')
            .select('allergy_id')
            .eq('user_id', user.id);
        await LocalDB.saveUserAllergies(
          userId: user.id,
          allergyIds: (allergies as List)
              .map<int>((a) => a['allergy_id'] as int)
              .toList(),
        );
      } catch (e) {
        print('⚠️ Could not reload allergies: $e');
      }

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
  // ──────────────────────────────────────────────
  static Future<AuthResult> logout() async {
    try {
      await _supabase.auth.signOut();
      await LocalDB.clearUserSession();
      return AuthResult(success: true, message: 'Logged out successfully');

    } catch (e) {
      return AuthResult(success: false, message: 'Logout failed');
    }
  }

  // ──────────────────────────────────────────────
  // IS LOGGED IN
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

  // ──────────────────────────────────────────────
  // UPDATE USER NAME
  // ──────────────────────────────────────────────
  static Future<bool> updateUserName({required String newName}) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      await _supabase
          .from('User')
          .update({'name': newName})
          .eq('user_id', user['user_id']);

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

  // ──────────────────────────────────────────────
  // UPLOAD PROFILE PHOTO
  // ──────────────────────────────────────────────
  static Future<String?> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('❌ No active session - user not authenticated');
        return null;
      }

      final file = File(filePath);
      final fileName = '$userId/avatar.jpg';

      await _supabase.storage
          .from('avatars')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // ✅ FIX: append timestamp so the URL changes on every upload.
      // Without this, Supabase always returns the same URL for the same
      // file path (userId/avatar.jpg), so _getCachedPhotoPath sees
      // urlChanged=false and NEVER re-downloads the new image.
      final baseUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      final photoUrl = '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      // ✅ FIX: delete the old local cache file immediately so that even
      // if there is a race condition, the stale image is never served.
      try {
        final dir = await getApplicationDocumentsDirectory();
        final cacheFile = File('${dir.path}/profile_$userId.jpg');
        if (await cacheFile.exists()) await cacheFile.delete();
      } catch (_) {}

      // Save versioned URL to Supabase User table
      await _supabase
          .from('User')
          .update({'photo_url': photoUrl})
          .eq('user_id', userId);

      // Save versioned URL to SQLite
      final db = await LocalDB.getDatabase();
      await db.update(
        'current_user',
        {'photo_url': photoUrl},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return photoUrl;
    } catch (e) {
      print('❌ Upload photo error: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // DELETE PROFILE PHOTO
  // ──────────────────────────────────────────────
  static Future<bool> deleteProfilePhoto({required String userId}) async {
    try {
      await _supabase.storage
          .from('avatars')
          .remove(['$userId/avatar.jpg']);

      await _supabase
          .from('User')
          .update({'photo_url': null})
          .eq('user_id', userId);

      final db = await LocalDB.getDatabase();
      await db.update(
        'current_user',
        {'photo_url': ''},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // ✅ Also delete the local cache file when photo is removed
      try {
        final dir = await getApplicationDocumentsDirectory();
        final cacheFile = File('${dir.path}/profile_$userId.jpg');
        if (await cacheFile.exists()) await cacheFile.delete();
        final urlFile = File('${dir.path}/profile_${userId}_url.txt');
        if (await urlFile.exists()) await urlFile.delete();
      } catch (_) {}

      return true;
    } catch (e) {
      print('❌ Delete photo error: $e');
      return false;
    }
  }
}