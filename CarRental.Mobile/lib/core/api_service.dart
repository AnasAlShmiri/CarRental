import '../data/models.dart';
import '../data/repositories.dart';
import 'api_client.dart';

/// Compatibility facade for older callers. Flutter is a customer application;
/// therefore this facade exposes only customer-safe operations.
class ApiService {
  ApiService._();

  static final _api = ApiClient();
  static final _auth = AuthRepository(_api);
  static final _cars = CarRepository(_api);
  static final _rentals = RentalRepository(_api);
  static final _customers = CustomerRepository(_api);

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final session = await _auth.login(email, password);
    return {
      'token': session.token,
      'expiresAtUtc': session.expiresAtUtc.toIso8601String(),
      'username': session.username,
      'role': session.role,
      'customerId': session.customerId,
      'name': session.name,
      'email': session.email,
      'phone': session.phone,
    };
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final session = await _auth.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    return {
      'token': session.token,
      'expiresAtUtc': session.expiresAtUtc.toIso8601String(),
      'username': session.username,
      'role': session.role,
      'customerId': session.customerId,
      'name': session.name,
      'email': session.email,
      'phone': session.phone,
    };
  }

  static Future<List<Car>> getAvailableCars() => _cars.getAvailableCars();

  static Future<Customer> getMyProfile() => _customers.getMyProfile();

  static Future<List<Rental>> getMyRentals() => _rentals.getMyRentals();

  static Future<Rental> createRental({
    required int carId,
    required DateTime start,
    required DateTime end,
  }) => _rentals.createRental(carId: carId, start: start, end: end);

  static Future<Rental> cancelRental(int id) => _rentals.cancelRental(id);
}
