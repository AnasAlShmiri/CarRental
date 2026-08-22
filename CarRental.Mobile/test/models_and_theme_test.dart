import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app/core/models.dart';
import 'package:car_rental_app/core/app_theme.dart';
import 'package:car_rental_app/data/repositories.dart';

void main() {
  group('Car.fromJson', () {
    test('يحلل استجابة /api/cars بشكل صحيح', () {
      const json = {
        'id': 5,
        'model': 'كامري',
        'brand': 'تويوتا',
        'pricePerDay': 150,
        'imageUrl': null,
        'status': 'Available',
        'createdAt': '2026-08-15T22:37:34Z',
      };
      final car = Car.fromJson(json);
      expect(car.id, 5);
      expect(car.brand, 'تويوتا');
      expect(car.pricePerDay, 150.0);
      expect(car.status, 'Available');
    });
  });

  group('Rental.fromJson', () {
    test('يحلل الإيجار مع الكائنات الفرعية car/customer', () {
      final json = {
        'id': 2,
        'carId': 5,
        'customerId': 2,
        'startDate': '2026-08-15T00:00:00',
        'endDate': '2026-08-20T00:00:00',
        'durationInDays': 5,
        'totalPrice': 750,
        'status': 'Active',
        'car': {
          'id': 5,
          'brand': 'تويوتا',
          'model': 'كامري',
          'pricePerDay': 150,
        },
        'customer': {'id': 2, 'name': 'تست عميل'},
      };
      final r = Rental.fromJson(json);
      expect(r.carName, 'تويوتا كامري');
      expect(r.customerName, 'تست عميل');
      expect(r.durationInDays, 5);
      expect(r.totalPrice, 750.0);
    });
  });

  test('تحويل تاريخ الحجز يحافظ على اليوم التقويمي', () {
    final iso = calendarDateUtcIso8601(DateTime(2026, 8, 23));
    expect(iso, '2026-08-23T00:00:00.000Z');
  });

  testWidgets('سمة التطبيق تستخدم خط Tajawal والألوان المعتمدة', (
    tester,
  ) async {
    expect(AppTheme.primary, const Color(0xFF1A73E8));
    final fontFamily = AppTheme.light.textTheme.bodyMedium?.fontFamily;
    expect(fontFamily, contains('Tajawal'));
    expect(AppTheme.light.brightness, Brightness.light);
  });
}
