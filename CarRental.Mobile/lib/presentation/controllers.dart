import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/session_store.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository);
  final AuthRepository repository;

  bool isLoading = false;
  bool isAuthenticated = false;
  String? username;
  String? errorMessage;

  Future<void> restore() async {
    final valid = await repository.hasSession();
    final role = await SessionStore.readRole();
    final customerId = await repository.customerId();
    isAuthenticated = valid && role?.toLowerCase() == 'customer' && customerId != null;
    if (isAuthenticated) {
      username = await repository.username();
    } else if (valid) {
      await repository.logout();
      username = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await repository.login(email, password);
      username = session.name ?? session.email ?? session.username;
      isAuthenticated = true;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'تعذر الاتصال بالخادم. تحقق من عنوان API والشبكة.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      username = session.name ?? session.email ?? session.username;
      isAuthenticated = true;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'تعذر إنشاء الحساب. تحقق من الاتصال وحاول مرة أخرى.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repository.logout();
    isAuthenticated = false;
    username = null;
    notifyListeners();
  }
}

class CarsController extends ChangeNotifier {
  CarsController(this.repository);
  final CarRepository repository;

  List<Car> cars = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cars = await repository.getAvailableCars();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'تعذر تحميل السيارات المتاحة.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Car> get availableCars => cars.where((car) => car.isAvailable).toList();
}

class CustomerController extends ChangeNotifier {
  CustomerController(this.repository);
  final CustomerRepository repository;

  Customer? profile;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await repository.getMyProfile();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'تعذر تحميل ملفك الشخصي.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class RentalsController extends ChangeNotifier {
  RentalsController(this.repository);
  final RentalRepository repository;

  List<Rental> rentals = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      rentals = await repository.getMyRentals();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'تعذر تحميل حجوزاتك.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required int carId,
    required DateTime start,
    required DateTime end,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.createRental(carId: carId, start: start, end: end);
      await load();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'تعذر إنشاء الحجز.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancel(int rentalId) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.cancelRental(rentalId);
      await load();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'تعذر إلغاء الحجز.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
