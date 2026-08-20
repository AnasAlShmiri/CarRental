import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../widgets/luxury_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AppScope.of(context).auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final username = auth.username ?? 'admin';
    return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: AppTheme.luxuryGradient, borderRadius: BorderRadius.circular(AppTheme.radiusLarge)), child: Row(children: [
        Container(width: 70, height: 70, decoration: BoxDecoration(gradient: AppTheme.goldGradient, shape: BoxShape.circle), alignment: Alignment.center, child: Text(username.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.midnight, fontSize: 27, fontWeight: FontWeight.w900))),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(username, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('مدير النظام', style: TextStyle(color: Color(0xB8FFFFFF), fontSize: 12)), const SizedBox(height: 12), LuxuryStatusChip(label: 'جلسة نشطة', color: AppTheme.primaryLight)])),
      ])),
      const SizedBox(height: 24),
      const LuxurySectionTitle(title: 'إعدادات الحساب'),
      const SizedBox(height: 12),
      LuxurySurface(padding: EdgeInsets.zero, child: Column(children: [
        _profileTile(icon: Icons.person_outline_rounded, title: 'اسم المستخدم', subtitle: username, color: AppTheme.primary),
        const Divider(height: 1, indent: 70),
        _profileTile(icon: Icons.verified_user_outlined, title: 'حالة الحساب', subtitle: 'حساب موثّق وجلسة آمنة', color: AppTheme.success),
        const Divider(height: 1, indent: 70),
        _profileTile(icon: Icons.translate_rounded, title: 'لغة التطبيق', subtitle: 'العربية — RTL', color: AppTheme.primary),
      ])),
      const SizedBox(height: 22),
      const LuxurySectionTitle(title: 'الأمان والخصوصية'),
      const SizedBox(height: 12),
      LuxurySurface(child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.success.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shield_rounded, color: AppTheme.success)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('حسابك محمي', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('يتم تأمين الاتصال وحفظ الجلسة باستخدام JWT.', style: TextStyle(color: AppTheme.muted, fontSize: 11, height: 1.45))]))])),
      const SizedBox(height: 24),
      OutlinedButton.icon(onPressed: () => _logout(context), icon: const Icon(Icons.logout_rounded, color: AppTheme.danger), label: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.danger))),
    ]);
  }

  Widget _profileTile({required IconData icon, required String title, required String subtitle, required Color color}) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)), title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 11))));
}
