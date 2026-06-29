import 'package:flutter/material.dart';
import 'services/history_services.dart';
import 'Screens/splash_screen.dart';

final historyService = HistoryService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await historyService.init();
  runApp(const QRApp());
}

class QRApp extends StatelessWidget {
  const QRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickIT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

class AppTheme {
  static const primary = Color(0xFF1A3C6E);
  static const accent  = Color(0xFF2558A8);
  static const bg      = Color(0xFFF4F6FB);

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
