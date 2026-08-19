import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_theme.dart';
import '../core/models.dart';

/// صفحة إيجاراتي — تعرض الحجوزات مع شارات حالة ملونة وفلتر.
class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> with SingleTickerProviderStateMixin {
  Future<List<Rental>>? _rentals;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _rentals = ApiService.getRentals();
  }

  String _statusAr(String status) => switch (status) {
        'Active' => 'نشط',
        'Completed' => 'مكتمل',
        'Cancelled' => 'ملغى',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'Active' => AppTheme.primary,
        'Completed' => AppTheme.success,
        'Cancelled' => AppTheme.danger,
        _ => Colors.grey,
      };

  void _reload() => setState(() => _rentals = ApiService.getRentals());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إيجاراتي', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: () => _showNewRentalSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('حجز جديد'),
          ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<Rental>>(
                future: _rentals,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text(snap.error.toString()));
                  }
                  final rentals = (snap.data ?? []).where((r) => _filter == null || r.status == _filter).toList();
                  if (rentals.isEmpty) {
                    return const Center(child: Text('لا توجد إيجارات'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rentals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _rentalCard(rentals[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    const options = [null, 'Active', 'Completed', 'Cancelled'];
    const labels = {'All': 'الكل', 'Active': 'نشط', 'Completed': 'مكتمل', 'Cancelled': 'ملغى'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      reverse: true,
      child: Row(
        children: options.map((opt) {
          final active = _filter == opt;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Text(labels[opt] ?? 'الكل'),
              selected: active,
              onSelected: (_) => setState(() => _filter = opt),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _rentalCard(Rental r) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: _statusColor(r.status).withOpacity(.10), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_long, color: _statusColor(r.status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(r.carName ?? '', style: const TextStyle(fontWeight: FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor(r.status).withOpacity(.10), borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusAr(r.status), style: TextStyle(color: _statusColor(r.status), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${r.startDate.substring(0, 10)} → ${r.endDate.substring(0, 10)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const Spacer(),
                const Text('المدة: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text('${r.durationInDays} يوم', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(r.customerName ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const Spacer(),
                Text('${r.totalPrice.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ModalBottomSheet: حجز جديد ───────────────────────────────
  Future<void> _showNewRentalSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final carIdCtrl = TextEditingController();
    final customerIdCtrl = TextEditingController();
    DateTime? start;
    DateTime? end;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('حجز جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: carIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم السيارة (CarId)'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'أدخل رقمًا صحيحًا' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: customerIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم العميل (CustomerId)'),
                  validator: (v) => int.tryParse(v ?? '') == null ? 'أدخل رقمًا صحيحًا' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => start = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(start == null ? 'تاريخ البدء' : '${start!.toLocal().toString().substring(0, 10)}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: start ?? DateTime.now(),
                            firstDate: start ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) setState(() => end = picked);
                        },
                        icon: const Icon(Icons.event_available, size: 16),
                        label: Text(end == null ? 'تاريخ الانتهاء' : '${end!.toLocal().toString().substring(0, 10)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false) || start == null || end == null) return;
                          setState(() => submitting = true);
                          try {
                            await ApiService.createRental(
                              carId: int.parse(carIdCtrl.text),
                              customerId: int.parse(customerIdCtrl.text),
                              start: start!,
                              end: end!,
                            );
                            if (sheet.mounted) Navigator.pop(sheet);
                            _reload();
                          } catch (e) {
                            if (!sheet.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          } finally {
                            if (sheet.mounted) setState(() => submitting = false);
                          }
                        },
                  child: submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('تأكيد الحجز'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
