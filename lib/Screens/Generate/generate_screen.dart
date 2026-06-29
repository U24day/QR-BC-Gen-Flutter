import 'package:flutter/material.dart';
import 'qr_generate_screen.dart';
import 'barcode_generate_screen.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
  @override
  State<GenerateScreen> createState() => _GenState();
}

class _GenState extends State<GenerateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Column(children: [
      Container(
        color: const Color(0xFF1A3C6E),
        child: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2_rounded), text: 'QR Code'),
            Tab(icon: Icon(Icons.barcode_reader),     text: 'Barcode'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tab, children: const [
          QrGenerateScreen(),
          BarcodeGenerateScreen(),
        ]),
      ),
    ]);
  }
}