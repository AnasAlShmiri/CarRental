import 'session_store.dart';

/// واجهة توافقية للملفات القديمة؛ مصدر الجلسة الفعلي هو SessionStore.
class AuthService {
  AuthService._();

  @Deprecated('Use AuthRepository.login or AuthRepository.register instead.')
  static Future<void> saveSession(
    String token,
    String username, {
    String role = 'Customer',
    int? customerId,
    String? name,
    String? email,
    String? phone,
  }) => SessionStore.save(
        token: token,
        username: username,
        role: role,
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 8)),
        customerId: customerId,
        name: name,
        email: email,
        phone: phone,
      );

  static Future<String?> get token => SessionStore.readToken();
  static Future<String?> get username => SessionStore.readUsername();
  static Future<bool> get isLoggedIn => SessionStore.hasValidSession();
  static Future<void> logout() => SessionStore.clear();
}
