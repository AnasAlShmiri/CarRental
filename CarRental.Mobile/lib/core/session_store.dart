import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore._();

  static const tokenKey = 'auth_token';
  static const usernameKey = 'auth_username';
  static const roleKey = 'auth_role';
  static const expiresAtKey = 'auth_expires_at';
  static const customerIdKey = 'auth_customer_id';
  static const nameKey = 'auth_name';
  static const emailKey = 'auth_email';
  static const phoneKey = 'auth_phone';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<void> save({
    required String token,
    required String username,
    required String role,
    required DateTime expiresAtUtc,
    int? customerId,
    String? name,
    String? email,
    String? phone,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(tokenKey, token);
    await prefs.setString(usernameKey, username);
    await prefs.setString(roleKey, role);
    await prefs.setString(expiresAtKey, expiresAtUtc.toIso8601String());
    if (customerId == null) {
      await prefs.remove(customerIdKey);
    } else {
      await prefs.setInt(customerIdKey, customerId);
    }
    await _setOrRemove(prefs, nameKey, name);
    await _setOrRemove(prefs, emailKey, email);
    await _setOrRemove(prefs, phoneKey, phone);
  }

  static Future<void> _setOrRemove(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  static Future<String?> readToken() async => (await _prefs).getString(tokenKey);
  static Future<String?> readUsername() async => (await _prefs).getString(usernameKey);
  static Future<String?> readRole() async => (await _prefs).getString(roleKey);
  static Future<int?> readCustomerId() async => (await _prefs).getInt(customerIdKey);
  static Future<String?> readName() async => (await _prefs).getString(nameKey);
  static Future<String?> readEmail() async => (await _prefs).getString(emailKey);
  static Future<String?> readPhone() async => (await _prefs).getString(phoneKey);

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
    await prefs.remove(customerIdKey);
    await prefs.remove(nameKey);
    await prefs.remove(emailKey);
    await prefs.remove(phoneKey);
  }
}
