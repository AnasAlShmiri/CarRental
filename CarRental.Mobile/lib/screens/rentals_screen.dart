import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../data/models.dart';
import '../presentation/controllers.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.of(context).rentals.load());
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).rentals;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final filtered = controller.rentals.where((item) => _filter == null || item.status == _filter).toList();
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('حجوزاتك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('تابع حالة إيجاراتك بسهولة', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                FloatingActionButton.small(heroTag: 'new-rental', onPressed: () => _showNewRentalSheet(), child: const Icon(Icons.add)),
              ]),
              const SizedBox(height: 18),
              _filterBar(),
              const SizedBox(height: 14),
              if (controller.isLoading && controller.rentals.isEmpty)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else if (controller.errorMessage != null && controller.rentals.isEmpty)
                _errorState(controller)
              else if (filtered.isEmpty)
                const Padding(padding: EdgeInsets.all(42), child: Center(child: Text('لا توجد إيجارات في هذا التصنيف')))
              else
                ...filtered.map(_rentalCard),
            ],
          ),
        );
      },
    );
  }

  Widget _filterBar() {
    const options = <String?>[null, 'Active', 'Completed', 'Cancelled'];
    const labels = {'Active': 'نشطة', 'Completed': 'مكتملة', 'Cancelled': 'ملغاة'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(children: options.map((option) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ChoiceChip(label: Text(option == null ? 'الكل' : labels[option]!), selected: _filter == option, onSelected: (_) => setState(() => _filter = option)),
      )).toList()),
    );
  }

  Widget _rentalCard(Rental rental) {
    final color = _statusColor(rental.status);
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.event_note, color: color)), const SizedBox(width: 12), Expanded(child: Text(rental.carName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), _statusPill(rental.status)]),
      const SizedBox(height: 14),
      const Divider(height: 1),
      const SizedBox(height: 12),
      Row(children: [const Icon(Icons.date_range, size: 17, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text(rental.dateRange, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))), Text('${rental.durationInDays} يوم', style: const TextStyle(fontWeight: FontWeight.w700))]),
      const SizedBox(height: 9),
      Row(children: [Text(rental.customerName, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)), const Spacer(), Text('${rental.totalPrice.toStringAsFixed(2)} ر.س', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15))]),
    ])));
  }

  Color _statusColor(String status) => switch (status) { 'Active' => AppTheme.primary, 'Completed' => AppTheme.success, 'Cancelled' => AppTheme.danger, _ => Colors.grey };

  Widget _statusPill(String status) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: _statusColor(status).withOpacity(.11), borderRadius: BorderRadius.circular(20)), child: Text(switch (status) { 'Active' => 'نشطة', 'Completed' => 'مكتملة', 'Cancelled' => 'ملغاة', _ => status }, style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _errorState(RentalsController controller) => Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Column(children: [const Icon(Icons.cloud_off, size: 44, color: Colors.grey), const SizedBox(height: 10), Text(controller.errorMessage ?? 'حدث خطأ'), const SizedBox(height: 12), OutlinedButton.icon(onPressed: controller.load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'))]));

  Future<void> _showNewRentalSheet() async {
    final services = AppScope.of(context);
    final cars = services.cars.availableCars;
    final customersFuture = services.customers.getCustomers();
    if (cars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد سيارات متاحة حاليًا')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _BookingSheet(cars: cars, customersFuture: customersFuture, onSubmit: (carId, customerId, start, end) async {
        final success = await services.rentals.create(carId: carId, customerId: customerId, start: start, end: end);
        if (success && sheetContext.mounted) Navigator.pop(sheetContext);
        return success ? null : services.rentals.errorMessage;
      }),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.cars, required this.customersFuture, required this.onSubmit});
  final List<Car> cars;
  final Future<List<Customer>> customersFuture;
  final Future<String?> Function(int carId, int customerId, DateTime start, DateTime end) onSubmit;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _formKey = GlobalKey<FormState>();
  Customer? _customer;
  Car? _car;
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: start ? (_start ?? now) : (_end ?? _start ?? now), firstDate: start ? now : (_start ?? now), lastDate: now.add(const Duration(days: 730)));
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _start == null || _end == null) {
      if (_start == null || _end == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر تاريخ البداية والنهاية')));
      return;
    }
    if (!_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تاريخ النهاية يجب أن يكون بعد البداية')));
      return;
    }
    setState(() => _submitting = true);
    final error = await widget.onSubmit(_car!.id, _customer!.id, _start!, _end!);
    if (!mounted) return;
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.viewInsetsOf(context).bottom + 20), child: Form(key: _formKey, child: FutureBuilder<List<Customer>>(future: widget.customersFuture, builder: (context, snapshot) {
    if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(44), child: Center(child: CircularProgressIndicator()));
    final customers = snapshot.data!;
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('إنشاء حجز جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      DropdownButtonFormField<Car>(value: _car, decoration: const InputDecoration(labelText: 'السيارة المتاحة', prefixIcon: Icon(Icons.directions_car_outlined)), items: widget.cars.map((car) => DropdownMenuItem(value: car, child: Text(car.displayName))).toList(), onChanged: (value) => setState(() => _car = value), validator: (value) => value == null ? 'اختر السيارة' : null),
      const SizedBox(height: 14),
      DropdownButtonFormField<Customer>(value: _customer, decoration: const InputDecoration(labelText: 'العميل', prefixIcon: Icon(Icons.person_outline)), items: customers.map((customer) => DropdownMenuItem(value: customer, child: Text(customer.name))).toList(), onChanged: (value) => setState(() => _customer = value), validator: (value) => value == null ? 'اختر العميل' : null),
      const SizedBox(height: 14),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _pickDate(true), icon: const Icon(Icons.calendar_today, size: 17), label: Text(_start == null ? 'بداية الحجز' : _format(_start!)))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () => _pickDate(false), icon: const Icon(Icons.event_available, size: 17), label: Text(_end == null ? 'نهاية الحجز' : _format(_end!))))]),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تأكيد الحجز')),
    ]));
  }));

  String _format(DateTime date) => '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
