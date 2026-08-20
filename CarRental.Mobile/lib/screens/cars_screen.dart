import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../data/models.dart';
import '../presentation/controllers.dart';
import '../widgets/luxury_widgets.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  String _filter = 'الكل';

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
        final visibleCars = controller.cars.where((car) => _filter == 'الكل' || (_filter == 'متاحة' ? car.isAvailable : !car.isAvailable)).toList();
        final available = controller.cars.where((car) => car.isAvailable).length;
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              LuxuryHero(eyebrow: 'CAR RENTAL SELECT', title: 'قيادة تستحق\nأن تُتذكر.', description: 'اختيارات راقية، خدمة سلسة، وتجربة مصممة حول رحلتك.', trailing: Container(width: 58, height: 58, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.16), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryLight, size: 28))),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: LuxuryMetric(label: 'إجمالي الأسطول', value: '${controller.cars.length}', icon: Icons.directions_car_rounded)), const SizedBox(width: 10), Expanded(child: LuxuryMetric(label: 'جاهزة للانطلاق', value: '$available', icon: Icons.key_rounded, accent: AppTheme.success))]),
              const SizedBox(height: 26),
              LuxurySectionTitle(title: 'اختياراتنا لك', trailing: Text('${visibleCars.length} سيارات', style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),
              _filterBar(),
              const SizedBox(height: 15),
              if (controller.isLoading && controller.cars.isEmpty)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
              else if (controller.errorMessage != null && controller.cars.isEmpty)
                _errorState(controller)
              else if (visibleCars.isEmpty)
                const LuxuryEmptyState(icon: Icons.directions_car_outlined, title: 'لا توجد مركبات هنا', description: 'ستظهر السيارات عندما تتوفر ضمن هذا التصنيف.')
              else
                ...visibleCars.map(_carCard),
            ],
          ),
        );
      },
    );
  }

  Widget _filterBar() => SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Row(children: ['الكل', 'متاحة', 'مؤجرة'].map((filter) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(filter), selected: _filter == filter, onSelected: (_) => setState(() => _filter = filter))).toList()));

  Widget _carCard(Car car) => GestureDetector(
        onTap: () => _showCarDetails(car),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLarge), border: Border.all(color: AppTheme.border), boxShadow: const [BoxShadow(color: Color(0x0A09111F), blurRadius: 22, offset: Offset(0, 9))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              SizedBox(height: 170, width: double.infinity, child: _carImage(car)),
              Positioned(top: 13, right: 13, child: LuxuryStatusChip(label: car.isAvailable ? 'متاحة الآن' : 'مؤجرة', color: car.isAvailable ? AppTheme.success : AppTheme.warning)),
              Positioned(bottom: 13, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.midnight.withOpacity(.82), borderRadius: BorderRadius.circular(12)), child: Text('${car.pricePerDay.toStringAsFixed(0)} ر.س / يوم', style: const TextStyle(color: AppTheme.primaryLight, fontSize: 11, fontWeight: FontWeight.w800)))),
            ]),
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(car.brand.toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(car.model, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 3), const Text('اختيار أنيق لرحلتك القادمة', style: TextStyle(color: AppTheme.muted, fontSize: 11))])), Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.arrow_back_rounded, color: AppTheme.midnight, size: 19))])),
          ]),
        ),
      );

  Widget _carImage(Car car) => DecoratedBox(
        decoration: BoxDecoration(gradient: AppTheme.luxuryGradient),
        child: car.imageUrl == null || car.imageUrl!.isEmpty
            ? const Center(child: Icon(Icons.directions_car_filled_rounded, color: AppTheme.primaryLight, size: 70))
            : Image.network(car.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.directions_car_filled_rounded, color: AppTheme.primaryLight, size: 70))),
      );

  Widget _errorState(CarsController controller) => LuxuryEmptyState(icon: Icons.cloud_off_rounded, title: 'تعذر تحميل الأسطول', description: controller.errorMessage ?? 'تحقق من اتصال API ثم حاول مرة أخرى.', action: OutlinedButton.icon(onPressed: controller.load, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')));

  Future<void> _showCarDetails(Car car) => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 135, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)), child: _carImage(car)),
        const SizedBox(height: 17),
        Text(car.brand.toUpperCase(), style: const TextStyle(color: AppTheme.primary, letterSpacing: 1.4, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(children: [Expanded(child: Text(car.model, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))), LuxuryStatusChip(label: car.isAvailable ? 'متاحة' : 'مؤجرة', color: car.isAvailable ? AppTheme.success : AppTheme.warning)]),
        const SizedBox(height: 12),
        Row(children: [const Icon(Icons.payments_outlined, color: AppTheme.primary, size: 19), const SizedBox(width: 7), Text('${car.pricePerDay.toStringAsFixed(2)} ر.س لليوم', style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), const Icon(Icons.verified_outlined, color: AppTheme.success, size: 18), const SizedBox(width: 5), const Text('اختيار موثوق', style: TextStyle(color: AppTheme.muted, fontSize: 11))]),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded), label: const Text('إغلاق التفاصيل')),
      ]));
}
