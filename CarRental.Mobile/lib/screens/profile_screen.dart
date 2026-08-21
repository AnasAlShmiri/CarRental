import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../widgets/luxury_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).customers.load();
    });
  }

  Future<void> _logout(BuildContext context) async {
    await AppScope.of(context).auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _editProfile(BuildContext context) async {
    final customers = AppScope.of(context).customers;
    final profile = customers.profile;
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.name);
    final phoneController = TextEditingController(text: profile.phone);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AnimatedBuilder(
        animation: customers,
        builder: (context, _) => AlertDialog(
          title: const Text('تعديل البيانات'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 2) {
                        return 'اكتب اسمًا من حرفين على الأقل';
                      }
                      if (text.length > 120) return 'الاسم طويل جدًا';
                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length > 30) return 'رقم الهاتف طويل جدًا';
                      if (text.isNotEmpty &&
                          !RegExp(r'^[0-9+()\- ]+$').hasMatch(text)) {
                        return 'صيغة رقم الهاتف غير صحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    initialValue: profile.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  if (customers.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        customers.errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: customers.isSaving
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: customers.isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final saved = await customers.updateProfile(
                        name: nameController.text,
                        phone: phoneController.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (saved) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث بياناتك بنجاح'),
                          ),
                        );
                      }
                    },
              child: customers.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final customers = AppScope.of(context).customers;
    final profile = customers.profile;
    final displayName = profile?.name ?? auth.username ?? 'العميل';
    final email = profile?.email ?? '—';
    final phone = profile?.phone ?? '—';
    final initial = displayName.trim().isEmpty
        ? 'ع'
        : displayName.characters.first;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: customers.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.luxuryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'حساب عميل',
                        style: TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const LuxuryStatusChip(
                        label: 'حساب نشط',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: profile == null
                      ? null
                      : () => _editProfile(context),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'تعديل البيانات',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const LuxurySectionTitle(title: 'بياناتي'),
          const SizedBox(height: 10),
          LuxurySurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _profileTile(
                  icon: Icons.person_outline_rounded,
                  title: 'الاسم الكامل',
                  subtitle: displayName,
                ),
                const Divider(height: 1, indent: 70),
                _profileTile(
                  icon: Icons.alternate_email_rounded,
                  title: 'البريد الإلكتروني',
                  subtitle: email,
                ),
                const Divider(height: 1, indent: 70),
                _profileTile(
                  icon: Icons.phone_outlined,
                  title: 'رقم الهاتف',
                  subtitle: phone,
                ),
              ],
            ),
          ),
          if (customers.errorMessage != null && profile == null) ...[
            const SizedBox(height: 12),
            LuxuryEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'تعذر تحميل الملف',
              description: customers.errorMessage!,
              action: OutlinedButton.icon(
                onPressed: customers.load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const LuxurySectionTitle(title: 'الأمان والخصوصية'),
          const SizedBox(height: 10),
          const LuxurySurface(
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.success),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'حسابك محمي. يتم تأمين الجلسة باستخدام JWT، ولا يستطيع العميل الوصول إلى بيانات عملاء آخرين.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            label: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 20),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.muted, fontSize: 11),
      ),
    ),
  );
}
