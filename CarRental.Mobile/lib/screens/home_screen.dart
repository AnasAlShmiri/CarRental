import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'cars_screen.dart';
import 'profile_screen.dart';
import 'rentals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _pages = const [CarsScreen(), RentalsScreen(), ProfileScreen()];
  final _titles = const ['السيارات', 'إيجاراتي', 'الملف الشخصي'];

  void _select(int index) {
    Navigator.popUntil(context, (route) => route.isFirst);
    setState(() => _selectedIndex = index);
  }

  Future<void> _logout() async {
    await AppScope.of(context).auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car), label: 'السيارات'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'إيجاراتي'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'الملف'),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.car_rental, size: 32, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text('كار رنتال', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('إدارة تأجير السيارات', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    Text('المستخدم: ${auth.username ?? 'admin'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.directions_car_outlined), title: const Text('السيارات'), selected: _selectedIndex == 0, onTap: () => _select(0)),
              ListTile(leading: const Icon(Icons.event_note_outlined), title: const Text('إيجاراتي'), selected: _selectedIndex == 1, onTap: () => _select(1)),
              ListTile(leading: const Icon(Icons.person_outline), title: const Text('الملف الشخصي'), selected: _selectedIndex == 2, onTap: () => _select(2)),
              const Spacer(),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)), onTap: _logout),
            ],
          ),
        ),
      ),
    );
  }
}
