import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';

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
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
      Center(child: Container(width: 86, height: 86, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.11), shape: BoxShape.circle), child: const Icon(Icons.person, size: 44, color: AppTheme.primary))),
      const SizedBox(height: 14),
      Text(auth.username ?? 'admin', textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('مدير النظام', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 28),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.person_outline, color: AppTheme.primary), title: const Text('اسم المستخدم'), subtitle: Text(auth.username ?? 'admin')),
        const Divider(height: 1, indent: 70),
        const ListTile(leading: Icon(Icons.verified_user_outlined, color: AppTheme.success), title: Text('حالة الحساب'), subtitle: Text('جلسة دخول نشطة')),
        const Divider(height: 1, indent: 70),
        const ListTile(leading: Icon(Icons.language, color: AppTheme.primary), title: Text('لغة التطبيق'), subtitle: Text('العربية — RTL')),
      ])),
      const SizedBox(height: 18),
      OutlinedButton.icon(onPressed: () => _logout(context), icon: const Icon(Icons.logout, color: Colors.red), label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red))),
    ]);
  }
}
