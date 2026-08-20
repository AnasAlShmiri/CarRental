import 'package:flutter/widgets.dart';

import 'core/api_client.dart';
import 'data/repositories.dart';
import 'presentation/controllers.dart';

class AppScope extends InheritedWidget {
  const AppScope({required this.services, required super.child, super.key});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}

class AppServices {
  AppServices._()
      : api = ApiClient(),
        auth = AuthController(AuthRepository(api)),
        cars = CarsController(CarRepository(api)),
        rentals = RentalsController(RentalRepository(api)),
        customers = CustomerRepository(api);

  final ApiClient api;
  final AuthController auth;
  final CarsController cars;
  final RentalsController rentals;
  final CustomerRepository customers;

  static AppServices create() => AppServices._();
}
