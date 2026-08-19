import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import '../core/app_theme.dart';
import 'login_screen.dart';

/// صفحة الملف الشخصي — تعرض بيانات الجلسة وخيار تسجيل الخروج.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<String?>(
        future: AuthService.username,
        builder: (context, snap) {
          final user = snap.data ?? 'admin';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 52, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 18),
                  Text(user, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('مدير النظام', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 28),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.verified_user, color: AppTheme.success), title: Text('الجلسة نشطة')),
                          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.security, color: AppTheme.primary), title: Text('التوكن محفوظ محليًا')),
                          ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.devices, color: AppTheme.warning), title: Text('تطبيق الجوال — CarRental')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                    onPressed: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
