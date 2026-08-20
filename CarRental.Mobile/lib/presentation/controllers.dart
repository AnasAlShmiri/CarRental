import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository);
  final AuthRepository repository;

  bool isLoading = false;
  bool isAuthenticated = false;
  String? username;
  String? errorMessage;

  Future<void> restore() async {
    isAuthenticated = await repository.hasSession();
    username = await repository.username();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await repository.login(username, password);
      this.username = session.username;
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
      cars = await repository.getCars();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'تعذر تحميل السيارات.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Car> get availableCars => cars.where((car) => car.isAvailable).toList();
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
      rentals = await repository.getRentals();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'تعذر تحميل الإيجارات.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required int carId,
    required int customerId,
    required DateTime start,
    required DateTime end,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.createRental(
        carId: carId,
        customerId: customerId,
        start: start,
        end: end,
      );
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
}
