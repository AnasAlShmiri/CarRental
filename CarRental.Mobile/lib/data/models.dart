import 'package:intl/intl.dart';

class AuthSession {
  final String token;
  final DateTime expiresAtUtc;
  final String username;
  final String role;
  final int? customerId;
  final String? name;
  final String? email;
  final String? phone;

  const AuthSession({
    required this.token,
    required this.expiresAtUtc,
    required this.username,
    required this.role,
    this.customerId,
    this.name,
    this.email,
    this.phone,
  });

  bool get isCustomer => role.toLowerCase() == 'customer';

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token']?.toString() ?? '',
    expiresAtUtc:
        DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
        DateTime.now().toUtc().add(const Duration(hours: 1)),
    username: json['username']?.toString() ?? json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    customerId: json['customerId'] == null ? null : _asInt(json['customerId']),
    name: json['name']?.toString(),
    email: json['email']?.toString(),
    phone: json['phone']?.toString(),
  );
}

class Car {
  final int id;
  final String brand;
  final String model;
  final double pricePerDay;
  final String status;
  final String? imageUrl;
  final DateTime? createdAt;

  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.pricePerDay,
    required this.status,
    this.imageUrl,
    this.createdAt,
  });

  String get displayName => '$brand $model'.trim();
  bool get isAvailable => status == 'Available';

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    id: _asInt(json['id']),
    brand: json['brand']?.toString() ?? '',
    model: json['model']?.toString() ?? '',
    pricePerDay: _asDouble(json['pricePerDay']),
    status: json['status']?.toString() ?? '',
    imageUrl: json['imageUrl']?.toString(),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: _asInt(json['id']),
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );
}

class Rental {
  final int id;
  final int carId;
  final int customerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationInDays;
  final double totalPrice;
  final String status;
  final DateTime? createdAt;
  final Car? car;
  final Customer? customer;

  const Rental({
    required this.id,
    required this.carId,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.durationInDays,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.car,
    this.customer,
  });

  String get carName => car?.displayName ?? 'سيارة #$carId';
  String get customerName => customer?.name ?? 'عميل #$customerId';
  String get dateRange {
    final format = DateFormat('yyyy/MM/dd');
    if (startDate == null || endDate == null) return 'لم تحدد التواريخ';
    return '${format.format(startDate!)} — ${format.format(endDate!)}';
  }

  factory Rental.fromJson(Map<String, dynamic> json) => Rental(
    id: _asInt(json['id']),
    carId: _asInt(json['carId']),
    customerId: _asInt(json['customerId']),
    startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
    endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
    durationInDays: _asInt(json['durationInDays']),
    totalPrice: _asDouble(json['totalPrice']),
    status: json['status']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    car: json['car'] is Map
        ? Car.fromJson(Map<String, dynamic>.from(json['car'] as Map))
        : null,
    customer: json['customer'] is Map
        ? Customer.fromJson(Map<String, dynamic>.from(json['customer'] as Map))
        : null,
  );
}

int _asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

double _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
