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
  AppServices._(ApiClient client)
      : api = client,
        auth = AuthController(AuthRepository(client)),
        cars = CarsController(CarRepository(client)),
        rentals = RentalsController(RentalRepository(client)),
        customers = CustomerController(CustomerRepository(client));


  final ApiClient api;
  final AuthController auth;
  final CarsController cars;
  final RentalsController rentals;
  final CustomerController customers;

  static AppServices create() => AppServices._(ApiClient());
}
