import '../core/api_client.dart';
import '../core/session_store.dart';
import 'models.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthSession> login(String username, String password) async {
    final data = await _api.post('/api/auth/login', body: {
      'username': username,
      'password': password,
    });
    final session = AuthSession.fromJson(Map<String, dynamic>.from(data as Map));
    if (session.token.isEmpty) throw const ApiException('لم يستلم التطبيق رمز الدخول');
    await SessionStore.save(
      token: session.token,
      username: session.username,
      role: session.role,
      expiresAtUtc: session.expiresAtUtc,
    );
    return session;
  }

  Future<void> logout() => SessionStore.clear();
  Future<bool> hasSession() => SessionStore.hasValidSession();
  Future<String?> username() => SessionStore.readUsername();
}

class CarRepository {
  CarRepository(this._api);
  final ApiClient _api;

  Future<List<Car>> getCars() async {
    final data = await _api.get('/api/cars');
    return (data as List)
        .map((item) => Car.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

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

  Future<List<Customer>> getCustomers() async {
    final data = await _api.get('/api/customers', authenticated: true);
    return (data as List)
        .map((item) => Customer.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Customer> createCustomer({
    required String name,
    required String email,
    required String phone,
  }) async {
    final data = await _api.post('/api/customers', authenticated: true, body: {
      'name': name,
      'email': email,
      'phone': phone,
    });
    return Customer.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

class RentalRepository {
  RentalRepository(this._api);
  final ApiClient _api;

  Future<List<Rental>> getRentals({int? customerId}) async {
    final path = customerId == null ? '/api/rentals' : '/api/rentals/customer/$customerId';
    final data = await _api.get(path, authenticated: customerId == null);
    return (data as List)
        .map((item) => Rental.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Rental> createRental({
    required int carId,
    required int customerId,
    required DateTime start,
    required DateTime end,
  }) async {
    final data = await _api.post('/api/rentals', body: {
      'carId': carId,
      'customerId': customerId,
      'startDate': start.toUtc().toIso8601String(),
      'endDate': end.toUtc().toIso8601String(),
    });
    return Rental.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
