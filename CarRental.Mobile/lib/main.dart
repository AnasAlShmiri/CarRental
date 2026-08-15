import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_theme.dart';
import 'core/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// نقطة دخول تطبيق تأجير السيارات — واجهة عربية RTL.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarRentalApp());
}

class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام تأجير السيارات',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// بوابة المصادقة: توجّه المستخدم إلى الشاشة الرئيسية أو تسجيل الدخول
/// بحسب وجود جلسة محفوظة.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn,
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return snap.data! ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
