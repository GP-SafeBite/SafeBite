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
    try {
      // Validate inputs (requirement 1.2, 1.3, 1.5 from your document)
      if (name.trim().isEmpty) {
        return AuthResult(
          success: false,
          message: 'Please enter your name',
        );
      }
      if (!email.contains('@') || !email.contains('.')) {
        return AuthResult(
          success: false,
          message: 'Please enter a valid email',
        );
      }
      if (password.length < 8) {
        return AuthResult(
          success: false,
          message: 'Password must be at least 8 characters',
        );
      }

      // Create account in Supabase Auth
      // This also fires the trigger → creates row in your User table
      // Supabase automatically sends 6-digit OTP to email
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // this goes into raw_user_meta_data in auth.users
                               // the trigger reads it and puts it in User.name
      );

      if (response.user == null) {
        return AuthResult(
          success: false,
          message: 'Registration failed. Please try again.',
        );
      }

      // Do NOT save to SQLite yet — wait until OTP is verified
      return AuthResult(
        success: true,
        message: 'A 6-digit verification code has been sent to $email',
        data: {
          'email': email,
          'name': name,
        },
      );

    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return AuthResult(
          success: false,
          message: 'This email is already registered. Please login.',
        );
      }
      return AuthResult(success: false, message: e.message);

    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error. Please check your internet.',
      );
    }
  }

  // ──────────────────────────────────────────────
  // VERIFY OTP
  // User enters the 6-digit code from email
  // Only after this succeeds do we save to SQLite
  // This matches Figure 9 in your document (enter verification code)
  // ──────────────────────────────────────────────
  static Future<AuthResult> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    try {
      if (otpCode.trim().length != 6) {
        return AuthResult(
          success: false,
          message: 'Please enter all 6 digits',
        );
      }

      // Send OTP to Supabase to verify
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otpCode,
        type: OtpType.signup,
      );

      if (response.user == null) {
        return AuthResult(
          success: false,
          message: 'Invalid or expired code. Please try again.',
        );
      }

      // OTP verified — now save user locally to SQLite
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
        data: {
          'userId': user.id,
          'email': email,
          'name': name,
        },
      );

    } on AuthException catch (e) {
      if (e.message.contains('expired')) {
        return AuthResult(
          success: false,
          message: 'Code has expired. Please request a new one.',
        );
      }
      return AuthResult(
        success: false,
        message: 'Invalid code. Please try again.',
      );

    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error. Please check your internet.',
      );
    }
  }

  // ──────────────────────────────────────────────
  // RESEND OTP
  // User didn't receive code or it expired
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
        success: true,
        message: 'A new code has been sent to $email',
      );

    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Could not resend code. Please try again.',
      );
    }
  }

  // ──────────────────────────────────────────────
  // LOGIN
  // For existing verified users
  // Matches Figure 5 and 6 in your document (login screens)
  // ──────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Please enter your email and password',
        );
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

      // Save to SQLite so app remembers login across sessions
      await LocalDB.saveUser(
        userId: user.id,
        email: email,
        name: name,
      );

      return AuthResult(
        success: true,
        message: 'Welcome back!',
        data: {
          'userId': user.id,
          'email': email,
          'name': name,
        },
      );

    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return AuthResult(
          success: false,
          message: 'Wrong email or password',
        );
      }
      // User registered but never verified OTP
      if (e.message.contains('Email not confirmed')) {
        return AuthResult(
          success: false,
          message: 'Please verify your email first',
          data: {
            'needsVerification': true,
            'email': email,
          },
        );
      }
      return AuthResult(success: false, message: e.message);

    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Connection error. Please check your internet.',
      );
    }
  }

  // ──────────────────────────────────────────────
  // LOGOUT
  // Clears Supabase session + SQLite local data
  // ──────────────────────────────────────────────
  static Future<AuthResult> logout() async {
    try {
      await _supabase.auth.signOut();
      await LocalDB.clearUser(); // clears user + allergies + scan history
      return AuthResult(success: true, message: 'Logged out successfully');

    } catch (e) {
      return AuthResult(success: false, message: 'Logout failed');
    }
  }

  // ──────────────────────────────────────────────
  // IS LOGGED IN
  // Used by splash screen to decide where to go
  // Checks Supabase session first, then SQLite fallback
  // ──────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    if (session != null) return true;

    final localUser = await LocalDB.getUser();
    return localUser != null;
  }

  // ──────────────────────────────────────────────
  // GET CURRENT USER
  // Returns local user data without hitting Supabase
  // ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await LocalDB.getUser();
  }
}