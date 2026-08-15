import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة الجلسة: حفظ التوكن واسم المستخدم بعد تسجيل الدخول.
class AuthService {
  AuthService._();

  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';

  /// حفظ بيانات الجلسة بعد نجاح تسجيل الدخول.
  static Future<void> saveSession(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
  }

  /// جلب التوكن المحفوظ (null إن لم تكن هناك جلسة).
  static Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// جلب اسم المستخدم المحفوظ.
  static Future<String?> get username async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// هل المستخدم مسجّل دخول حاليًا؟
  static Future<bool> get isLoggedIn async => (await token) != null;

  /// إنهاء الجلسة (تسجيل خروج).
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
  }
}
