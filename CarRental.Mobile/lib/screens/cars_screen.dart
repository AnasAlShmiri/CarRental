import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../data/models.dart';
import '../presentation/controllers.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.of(context).cars.load());
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).cars;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final available = controller.cars.where((car) => car.isAvailable).length;
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _welcomeHeader(),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _statCard('إجمالي السيارات', '${controller.cars.length}', Icons.directions_car, AppTheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('متاحة الآن', '$available', Icons.check_circle_outline, AppTheme.success)),
              ]),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('أسطول السيارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${controller.cars.length} سيارات', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              if (controller.isLoading && controller.cars.isEmpty)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else if (controller.errorMessage != null && controller.cars.isEmpty)
                _errorState(controller)
              else if (controller.cars.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('لا توجد سيارات في الأسطول')))
              else
                ...controller.cars.map(_carCard),
            ],
          ),
        );
      },
    );
  }

  Widget _welcomeHeader() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withOpacity(.78)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('استكشف أسطولنا', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('اختر سيارتك المناسبة وابدأ حجزك بسهولة', style: TextStyle(color: Colors.white70, fontSize: 13))])),
          Icon(Icons.local_offer_outlined, color: Colors.white, size: 42),
        ]),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) => Card(
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 21)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))])),
        ])),
      );

  Widget _carCard(Car car) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCarDetails(car),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            _carImage(car),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(car.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 6), Text('${car.pricePerDay.toStringAsFixed(0)} ر.س / اليوم', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)), const SizedBox(height: 8), _statusPill(car.status)])),
            const Icon(Icons.chevron_left, color: Colors.grey),
          ])),
        ),
      );

  Widget _carImage(Car car) => Container(
        width: 82,
        height: 78,
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.08), borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: car.imageUrl == null || car.imageUrl!.isEmpty
            ? const Icon(Icons.directions_car, color: AppTheme.primary, size: 36)
            : Image.network(car.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: AppTheme.primary, size: 36)),
      );

  Widget _statusPill(String status) {
    final available = status == 'Available';
    final color = available ? AppTheme.success : AppTheme.warning;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(20)), child: Text(available ? 'متاحة' : 'مؤجَّرة', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)));
  }

  Widget _errorState(CarsController controller) => Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Column(children: [const Icon(Icons.cloud_off, size: 44, color: Colors.grey), const SizedBox(height: 10), Text(controller.errorMessage ?? 'حدث خطأ'), const SizedBox(height: 12), OutlinedButton.icon(onPressed: controller.load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))]));

  void _showCarDetails(Car car) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(car.displayName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('السعر اليومي: ${car.pricePerDay.toStringAsFixed(2)} ر.س'),
            const SizedBox(height: 8),
            Row(children: [const Text('الحالة: '), _statusPill(car.status)]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text('إغلاق'))),
          ]),
        ),
      );
}
