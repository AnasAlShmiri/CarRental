import 'session_store.dart';

/// واجهة توافقية للملفات القديمة؛ مصدر الجلسة الفعلي هو SessionStore.
class AuthService {
  AuthService._();

  static Future<void> saveSession(String token, String username) => SessionStore.save(
        token: token,
        username: username,
        role: 'Admin',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 8)),
      );

  static Future<String?> get token => SessionStore.readToken();
  static Future<String?> get username => SessionStore.readUsername();
  static Future<bool> get isLoggedIn => SessionStore.hasValidSession();
  static Future<void> logout() => SessionStore.clear();
}
