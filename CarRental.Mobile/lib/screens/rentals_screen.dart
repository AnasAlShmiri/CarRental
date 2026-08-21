import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../data/models.dart';
import '../presentation/controllers.dart';
import '../widgets/luxury_widgets.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  String? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).rentals.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).rentals;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final filtered = controller.rentals
            .where((item) => _filter == null || item.status == _filter)
            .toList();
        final active = controller.rentals
            .where((item) => item.status == 'Active')
            .length;
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              LuxuryHero(
                eyebrow: 'YOUR JOURNEY',
                title: 'كل رحلة تبدأ\nبتفصيل جميل.',
                description:
                    'استعرض حجوزاتك وتابع تفاصيل رحلتك من لحظة الاختيار حتى العودة.',
                trailing: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppTheme.primaryLight,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LuxuryMetric(
                      label: 'كل الحجوزات',
                      value: '${controller.rentals.length}',
                      icon: Icons.calendar_month_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LuxuryMetric(
                      label: 'رحلات نشطة',
                      value: '$active',
                      icon: Icons.timelapse_rounded,
                      accent: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              LuxuryQuickAction(
                icon: Icons.add_road_rounded,
                label: 'احجز سيارة الآن',
                onTap: _showNewRentalSheet,
              ),
              const SizedBox(height: 25),
              const LuxurySectionTitle(title: 'حجوزاتي'),
              const SizedBox(height: 12),
              _filterBar(),
              const SizedBox(height: 15),
              if (controller.isLoading && controller.rentals.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (controller.errorMessage != null &&
                  controller.rentals.isEmpty)
                _errorState(controller)
              else if (filtered.isEmpty)
                LuxuryEmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'لا توجد حجوزات بعد',
                  description: 'ابدأ رحلتك الأولى باختيار سيارة من الأسطول.',
                  action: controller.isLoading
                      ? null
                      : OutlinedButton.icon(
                          onPressed: _showNewRentalSheet,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('إنشاء حجز'),
                        ),
                )
              else
                ...filtered.map(_rentalCard),
            ],
          ),
        );
      },
    );
  }

  Widget _filterBar() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [null, 'Active', 'Completed', 'Cancelled']
              .map(
                (option) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(
                      option == null ? 'الكل' : _statusLabel(option),
                    ),
                    selected: _filter == option,
                    onSelected: (_) => setState(() => _filter = option),
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _rentalCard(Rental rental) {
    final color = _statusColor(rental.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0809111F),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: AppTheme.luxuryGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppTheme.primaryLight,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rental.carName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LuxuryStatusChip(
                label: _statusLabel(rental.status),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rental.dateRange,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${rental.durationInDays} يوم',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'القيمة الإجمالية',
                style: TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${rental.totalPrice.toStringAsFixed(2)} ر.س',
                style: const TextStyle(
                  color: AppTheme.midnight,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (rental.status == 'Active') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: controllerBusy ? null : () => _cancelRental(rental),
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.danger),
                label: const Text(
                  'إلغاء الحجز',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get controllerBusy => AppScope.of(context).rentals.isSubmitting;

  Future<void> _cancelRental(Rental rental) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء الحجز؟'),
        content: const Text('سيتم تحرير السيارة بعد إلغاء هذا الحجز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إلغاء الحجز'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final controller = AppScope.of(context).rentals;
    final success = await controller.cancel(rental.id);
    if (!mounted || success || controller.errorMessage == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.errorMessage!)),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'Active' => 'نشطة',
        'Completed' => 'مكتملة',
        'Cancelled' => 'ملغاة',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'Active' => AppTheme.success,
        'Completed' => AppTheme.primary,
        'Cancelled' => AppTheme.danger,
        _ => AppTheme.muted,
      };

  Widget _errorState(RentalsController controller) => LuxuryEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'تعذر تحميل حجوزاتك',
        description: controller.errorMessage ?? 'تحقق من الاتصال ثم أعد المحاولة.',
        action: OutlinedButton.icon(
          onPressed: controller.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );

  Future<void> _showNewRentalSheet() async {
    final services = AppScope.of(context);
    await services.cars.load();
    if (!mounted) return;
    final cars = services.cars.availableCars;
    if (cars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد سيارات متاحة حاليًا')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _BookingSheet(
        cars: cars,
        onSubmit: (carId, start, end) async {
          final success = await services.rentals.create(
            carId: carId,
            start: start,
            end: end,
          );
          if (success && sheetContext.mounted) Navigator.pop(sheetContext);
          return success ? null : services.rentals.errorMessage;
        },
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.cars, required this.onSubmit});

  final List<Car> cars;
  final Future<String?> Function(int carId, DateTime start, DateTime end) onSubmit;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _formKey = GlobalKey<FormState>();
  Car? _car;
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? (_start ?? now) : (_end ?? _start ?? now),
      firstDate: start ? now : (_start ?? now),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تاريخ البداية والنهاية')),
      );
      return;
    }
    if (!_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ النهاية يجب أن يكون بعد البداية')),
      );
      return;
    }
    setState(() => _submitting = true);
    final error = await widget.onSubmit(_car!.id, _start!, _end!);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 5,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'صمّم رحلتك القادمة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                const Text(
                  'اختر السيارة والتواريخ، وسنتولى باقي التفاصيل.',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<Car>(
                  value: _car,
                  decoration: const InputDecoration(
                    labelText: 'السيارة المتاحة',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  items: widget.cars
                      .map(
                        (car) => DropdownMenuItem(
                          value: car,
                          child: Text(car.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _car = value),
                  validator: (value) => value == null ? 'اختر السيارة' : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _dateButton(
                        label: _start == null
                            ? 'بداية الرحلة'
                            : _format(_start!),
                        icon: Icons.login_rounded,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateButton(
                        label: _end == null ? 'نهاية الرحلة' : _format(_end!),
                        icon: Icons.logout_rounded,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryLight,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _submitting ? 'جارٍ تأكيد الرحلة...' : 'تأكيد الحجز',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _dateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  String _format(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
