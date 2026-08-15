import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_theme.dart';
import '../core/models.dart';

/// صفحة السيارات — تعرض الأسطول كبطاقات مع حالة ملونة.
class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  Future<List<Car>>? _cars;

  @override
  void initState() {
    super.initState();
    _cars = ApiService.getCars();
  }

  String _statusAr(String status) => switch (status) {
        'Available' => 'متاحة',
        'Rented' => 'مؤجَّرة',
        'UnderMaintenance' => 'قيد الصيانة',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'Available' => AppTheme.success,
        'Rented' => AppTheme.primary,
        'UnderMaintenance' => AppTheme.warning,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسطول السيارات', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _cars = ApiService.getCars()),
        child: FutureBuilder<List<Car>>(
          future: _cars,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text(snap.error.toString()));
            }
            final cars = snap.data ?? [];
            if (cars.isEmpty) {
              return const Center(child: Text('لا توجد سيارات في الأسطول'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cars.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _carCard(cars[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _carCard(Car car) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetails(car),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.car_rental, size: 38, color: AppTheme.primary.withOpacity(.7)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${car.brand} ${car.model}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(car.status).withOpacity(.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_statusAr(car.status), style: TextStyle(color: _statusColor(car.status), fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Text('${car.pricePerDay.toStringAsFixed(2)} ر.س / يوم', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(Car car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Icon(Icons.car_rental, size: 34, color: AppTheme.primary)),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text('${car.brand} ${car.model}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.attach_money, color: AppTheme.primary), title: Text('${car.pricePerDay.toStringAsFixed(2)} ر.س يوميًا')),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline, color: AppTheme.primary), title: Text('الحالة: ${_statusAr(car.status)}')),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today, color: AppTheme.primary), title: Text('أضيفت في: ${car.createdAt.substring(0, 10)}')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
