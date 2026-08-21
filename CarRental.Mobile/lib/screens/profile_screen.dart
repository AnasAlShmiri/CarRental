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

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final customers = AppScope.of(context).customers;
    final profile = customers.profile;
    final displayName = profile?.name ?? auth.username ?? 'العميل';
    final email = profile?.email ?? '—';
    final phone = profile?.phone ?? '—';

    return RefreshIndicator(
      onRefresh: customers.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.luxuryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.isEmpty ? 'ع' : displayName.characters.first,
                    style: const TextStyle(
                      color: AppTheme.midnight,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'حساب عميل',
                        style: TextStyle(
                          color: Color(0xB8FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const LuxuryStatusChip(
                        label: 'جلسة نشطة',
                        color: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const LuxurySectionTitle(title: 'بياناتي'),
          const SizedBox(height: 12),
          LuxurySurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _profileTile(
                  icon: Icons.person_outline_rounded,
                  title: 'الاسم الكامل',
                  subtitle: displayName,
                  color: AppTheme.primary,
                ),
                const Divider(height: 1, indent: 70),
                _profileTile(
                  icon: Icons.alternate_email_rounded,
                  title: 'البريد الإلكتروني',
                  subtitle: email,
                  color: AppTheme.primary,
                ),
                const Divider(height: 1, indent: 70),
                _profileTile(
                  icon: Icons.phone_outlined,
                  title: 'رقم الهاتف',
                  subtitle: phone,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
          if (customers.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              customers.errorMessage!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 22),
          const LuxurySectionTitle(title: 'الأمان والخصوصية'),
          const SizedBox(height: 12),
          const LuxurySurface(
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: AppTheme.success),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'حسابك محمي. يتم تأمين الجلسة باستخدام JWT، ولا يستطيع العميل الوصول إلى بيانات عملاء آخرين.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
    required Color color,
  }) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
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
