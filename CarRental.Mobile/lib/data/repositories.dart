import '../core/api_client.dart';
import '../core/session_store.dart';
import 'models.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _api.post('/api/customer-auth/register', body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return _saveSession(data);
  }

  Future<AuthSession> login(String email, String password) async {
    final data = await _api.post('/api/customer-auth/login', body: {
      'email': email,
      'password': password,
    });
    return _saveSession(data);
  }

  Future<AuthSession> _saveSession(Object? raw) async {
    final session = AuthSession.fromJson(Map<String, dynamic>.from(raw as Map));
    if (session.token.isEmpty || session.customerId == null) {
      throw const ApiException('لم يستلم التطبيق جلسة عميل صالحة');
    }
    await SessionStore.save(
      token: session.token,
      username: session.username,
      role: session.role,
      expiresAtUtc: session.expiresAtUtc,
      customerId: session.customerId,
      name: session.name,
      email: session.email,
      phone: session.phone,
    );
    return session;
  }

  Future<void> logout() => SessionStore.clear();
  Future<bool> hasSession() => SessionStore.hasValidSession();
  Future<String?> username() => SessionStore.readUsername();
  Future<int?> customerId() => SessionStore.readCustomerId();
}

class CarRepository {
  CarRepository(this._api);
  final ApiClient _api;

  Future<List<Car>> getAvailableCars() async {
    final data = await _api.get('/api/cars/available');
    return (data as List)
        .map((item) => Car.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}

class CustomerRepository {
  CustomerRepository(this._api);
  final ApiClient _api;

  Future<Customer> getMyProfile() async {
    final data = await _api.get('/api/customer-auth/me', authenticated: true);
    return Customer.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

class RentalRepository {
  RentalRepository(this._api);
  final ApiClient _api;

  Future<List<Rental>> getMyRentals() async {
    final data = await _api.get('/api/customer/rentals', authenticated: true);
    return (data as List)
        .map((item) => Rental.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Rental> createRental({
    required int carId,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _api.post('/api/customer/rentals', authenticated: true, body: {
      'carId': carId,
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
    });
    return Rental.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Rental> cancelRental(int id) async {
    final data = await _api.post('/api/customer/rentals/$id/cancel', authenticated: true);
    return Rental.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
