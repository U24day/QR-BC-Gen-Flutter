import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'generate/generate_screen.dart';
import 'scan/scan_screen.dart';
import 'history/history_screen.dart';
import 'favorites/favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  int _idx = 0;

  final _pages = const [
    DashboardScreen(),
    GenerateScreen(),
    ScanScreen(),
    HistoryScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title:             const Text('QuickIT',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1A3C6E).withOpacity(0.12),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF1A3C6E)),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box, color: Color(0xFF1A3C6E)),
              label: 'Generate'),
          NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon:
              Icon(Icons.qr_code_scanner, color: Color(0xFF1A3C6E)),
              label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: Color(0xFF1A3C6E)),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star, color: Color(0xFF1A3C6E)),
              label: 'Favorites'),
        ],
      ),
    );
  }
}