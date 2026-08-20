import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore._();

  static const tokenKey = 'auth_token';
  static const usernameKey = 'auth_username';
  static const roleKey = 'auth_role';
  static const expiresAtKey = 'auth_expires_at';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<void> save({
    required String token,
    required String username,
    required String role,
    required DateTime expiresAtUtc,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(tokenKey, token);
    await prefs.setString(usernameKey, username);
    await prefs.setString(roleKey, role);
    await prefs.setString(expiresAtKey, expiresAtUtc.toIso8601String());
  }

  static Future<String?> readToken() async => (await _prefs).getString(tokenKey);
  static Future<String?> readUsername() async => (await _prefs).getString(usernameKey);
  static Future<String?> readRole() async => (await _prefs).getString(roleKey);

  static Future<DateTime?> readExpiry() async {
    final raw = (await _prefs).getString(expiresAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<bool> hasValidSession() async {
    final token = await readToken();
    if (token == null || token.isEmpty) return false;
    final expiry = await readExpiry();
    return expiry == null || expiry.isAfter(DateTime.now().toUtc());
  }

  static Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(tokenKey);
    await prefs.remove(usernameKey);
    await prefs.remove(roleKey);
    await prefs.remove(expiresAtKey);
  }
}
