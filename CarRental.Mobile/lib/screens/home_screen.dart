import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import 'cars_screen.dart';
import 'rentals_screen.dart';
import 'profile_screen.dart';

/// الشاشة الرئيسية — تحمل BottomNavigationBar بثلاث صفحات وDrawer للتنقل.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const List<Widget> _pages = [
    CarsScreen(),
    RentalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.car_rental_outlined), selectedIcon: Icon(Icons.car_rental), label: 'السيارات'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'إيجاراتي'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'الملف'),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.car_rental, size: 32, color: Color(0xFF1A73E8)),
                    ),
                    const SizedBox(height: 14),
                    const Text('نظام تأجير السيارات', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    FutureBuilder<String?>(
                      future: AuthService.username,
                      builder: (context, snap) => Text('المستخدم: ${snap.data ?? "admin"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.car_rental_outlined, color: Color(0xFF1A73E8)),
                      title: const Text('السيارات'),
                      onTap: () { Navigator.pop(context); setState(() => _index = 0); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF1A73E8)),
                      title: const Text('إيجاراتي'),
                      onTap: () { Navigator.pop(context); setState(() => _index = 1); },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: Color(0xFF1A73E8)),
                      title: const Text('الملف الشخصي'),
                      onTap: () { Navigator.pop(context); setState(() => _index = 2); },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFBA1A1A))),
                onTap: () async {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
