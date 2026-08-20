import '../data/models.dart';
import '../data/repositories.dart';
import 'api_client.dart';

/// Compatibility facade; new screens use Controllers and Repositories directly.
class ApiService {
  ApiService._();

  static final _api = ApiClient();
  static final _auth = AuthRepository(_api);
  static final _cars = CarRepository(_api);
  static final _rentals = RentalRepository(_api);
  static final _customers = CustomerRepository(_api);

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final session = await _auth.login(username, password);
    return {
      'token': session.token,
      'expiresAtUtc': session.expiresAtUtc.toIso8601String(),
      'username': session.username,
      'role': session.role,
    };
  }

  static Future<List<Car>> getCars() => _cars.getCars();

  static Future<List<Car>> getAvailableCars() => _cars.getAvailableCars();

  static Future<List<Rental>> getRentals() => _rentals.getRentals();

  static Future<Rental> createRental({
    required int carId,
    required int customerId,
    required DateTime start,
    required DateTime end,
  }) => _rentals.createRental(
        carId: carId,
        customerId: customerId,
        start: start,
        end: end,
      );

  static Future<List<Customer>> getCustomers() => _customers.getCustomers();

  static Future<Customer> createCustomer({
    required String name,
    required String email,
    required String phone,
  }) => _customers.createCustomer(name: name, email: email, phone: phone);
}
