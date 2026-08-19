/// نماذج البيانات الأساسية المتبادلة مع الـ API.

class Car {
  final int id;
  final String brand;
  final String model;
  final double pricePerDay;
  final String status;
  final String? imageUrl;
  final String createdAt;

  const Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.pricePerDay,
    required this.status,
    this.imageUrl,
    required this.createdAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    // حقول الـ API قد تختلف قليلاً عن نماذج MVC؛ نقبل الأسماء الأكثر شيوعًا.
    String? image;
    try {
      image = json['imageUrl']?.toString() ?? json['image_url']?.toString();
    } catch (_) {
      image = null;
    }
    return Car(
      id: json['id'] as int,
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? '',
      imageUrl: image,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class Rental {
  final int id;
  final String? carName;
  final String? customerName;
  final String startDate;
  final String endDate;
  final int durationInDays;
  final double totalPrice;
  final String status;

  const Rental({
    required this.id,
    this.carName,
    this.customerName,
    required this.startDate,
    required this.endDate,
    required this.durationInDays,
    required this.totalPrice,
    required this.status,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    final car = json['car'];
    final customer = json['customer'];
    return Rental(
      id: json['id'] as int,
      carName: car != null ? '${car['brand'] ?? ''} ${car['model'] ?? ''}'.trim() : 'سيارة #${json['carId']}',
      customerName: customer?['name']?.toString() ?? 'عميل #${json['customerId']}',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      durationInDays: json['durationInDays'] as int? ?? 0,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;

  const Customer({required this.id, required this.name, required this.email, required this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
