import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'models.dart';

/// خدمة الاتصال بواجهة Web API الخاصة بمشروع CarRental.
class ApiService {
  ApiService._();

  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (auth) {
      final token = await AuthService.token;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── المصادقة ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: await _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['message'] ?? body['error'] ?? 'فشل تسجيل الدخول');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // ── السيارات ────────────────────────────────────────────────
  static Future<List<Car>> getCars() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/cars'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception('تعذر تحميل السيارات');
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Car>> getAvailableCars() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/cars/available'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception('تعذر تحميل السيارات المتاحة');
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── الإيجارات ────────────────────────────────────────────────
  static Future<List<Rental>> getRentals() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/rentals'),
      headers: await _headers(auth: true),
    );
    if (response.statusCode != 401) throw Exception('تعذر تحميل الإيجارات — تأكد من تسجيل الدخول');
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Rental.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Rental> createRental({
    required int carId,
    required int customerId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/rentals'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'carId': carId,
        'customerId': customerId,
        'startDate': start.toUtc().toIso8601String(),
        'endDate': end.toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['message'] ?? 'فشل إنشاء الحجز');
    }
    return Rental.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  // ── العملاء ────────────────────────────────────────────────
  static Future<List<Customer>> getCustomers() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/customers'),
      headers: await _headers(auth: true),
    );
    if (response.statusCode != 200) throw Exception('تعذر تحميل العملاء');
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Customer> createCustomer({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/api/customers'),
      headers: await _headers(auth: true),
      body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
    );
    if (response.statusCode != 201) throw Exception('فشل إضافة العميل');
    return Customer.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }
}
