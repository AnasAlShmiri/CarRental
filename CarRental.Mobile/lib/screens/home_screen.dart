import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/app_theme.dart';
import '../widgets/luxury_widgets.dart';
import 'cars_screen.dart';
import 'profile_screen.dart';
import 'rentals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final _pages = const [CarsScreen(), RentalsScreen(), ProfileScreen()];
  final _titles = const ['أسطول السيارات', 'حجوزاتي', 'حسابي'];
  final _subtitles = const ['تجربة قيادة بمستوى مختلف', 'كل رحلاتك في مكان واحد', 'إدارة حسابك وتفضيلاتك'];

  void _select(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
    setState(() => _selectedIndex = index);
    final services = AppScope.of(context);
    if (index == 0) {
      services.cars.load();
    } else if (index == 1) {
      services.rentals.load();
    }
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
      key: _scaffoldKey,
      body: LuxuryPageBackground(
        child: SafeArea(
          child: Column(children: [
            LuxuryTopBar(title: _titles[_selectedIndex], subtitle: _subtitles[_selectedIndex], onMenu: () => _scaffoldKey.currentState?.openDrawer(), action: _topAvatar(auth.username)),
            Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
          ]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), selectedIcon: Icon(Icons.directions_car_rounded), label: 'الأسطول'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'الحجوزات'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
      drawer: _drawer(auth.username),
    );
  }

  Widget _topAvatar(String? username) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppTheme.midnight, borderRadius: BorderRadius.circular(15)),
        alignment: Alignment.center,
        child: Text((username ?? 'A').substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w900)),
      );

  Drawer _drawer(String? username) => Drawer(
        backgroundColor: AppTheme.midnight,
        child: SafeArea(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(17)), child: const Icon(Icons.directions_car_filled_rounded, color: AppTheme.midnight, size: 27)),
            const SizedBox(width: 13),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CAR RENTAL', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w900, letterSpacing: 1.6, fontSize: 14)), SizedBox(height: 3), Text('Luxury mobility', style: TextStyle(color: Color(0x9FFFFFFF), fontSize: 11))])),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
          ]),
          const SizedBox(height: 34),
          Text('مرحبًا بك، ${username ?? 'عميلنا العزيز'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('أدر رحلاتك بتفاصيل أنيقة', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
          const SizedBox(height: 30),
          _drawerItem(icon: Icons.directions_car_rounded, label: 'أسطول السيارات', selected: _selectedIndex == 0, onTap: () => _select(0)),
          _drawerItem(icon: Icons.calendar_month_rounded, label: 'الحجوزات', selected: _selectedIndex == 1, onTap: () => _select(1)),
          _drawerItem(icon: Icons.person_rounded, label: 'حسابي', selected: _selectedIndex == 2, onTap: () => _select(2)),
          const Spacer(),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.09))), child: const Row(children: [Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 20), SizedBox(width: 10), Expanded(child: Text('بياناتك محمية بتشفير آمن', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)))])),
          const SizedBox(height: 14),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: const Icon(Icons.logout_rounded, color: Color(0xFFE2A1A1)), title: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFE2A1A1), fontWeight: FontWeight.w700)), onTap: _logout),
        ]))),
      );

  Widget _drawerItem({required IconData icon, required String label, required bool selected, required VoidCallback onTap}) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(color: selected ? AppTheme.primary.withOpacity(.16) : Colors.transparent, borderRadius: BorderRadius.circular(15)),
        child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12), leading: Icon(icon, color: selected ? AppTheme.primaryLight : Colors.white60), title: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)), onTap: onTap),
      );
}
