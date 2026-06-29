import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/code_item.dart';
import '../../main.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanState();
}

class _ScanState extends State<ScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _flashOn  = false;
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused)  _ctrl.stop();
    if (state == AppLifecycleState.resumed) _ctrl.start();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_scanning) return;
    final bc = capture.barcodes.firstOrNull;
    if (bc == null || bc.rawValue == null) return;

    setState(() => _scanning = false);
    HapticFeedback.mediumImpact();
    await _ctrl.stop();

    final item = CodeItem(
      type: 'qr',
      subtype: bc.format.name,
      data: bc.rawValue!,
      label: bc.rawValue!.length > 40
          ? '${bc.rawValue!.substring(0, 40)}…' : bc.rawValue!,
      isGenerated: false,
    );
    await historyService.add(item);

    if (mounted) _showResult(bc.rawValue!, bc.format.name);
  }

  void _showResult(String data, String format) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF1A3C6E), size: 52),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF1A3C6E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(format,
                style: const TextStyle(fontSize: 12,
                    color: Color(0xFF1A3C6E), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
          Text(data,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _ResultAction(icon: Icons.copy, label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied!')));
                }),
            _ResultAction(icon: Icons.share, label: 'Share',
                onTap: () {
                  Share.share(data);
                  Navigator.pop(context);
                }),
            _ResultAction(icon: Icons.open_in_new, label: 'Open',
                onTap: () {
                  // Use url_launcher for links
                  Navigator.pop(context);
                }),
            _ResultAction(icon: Icons.star_border, label: 'Favorite',
                onTap: () async {
                  final items = historyService.getAll();
                  if (items.isNotEmpty) {
                    await historyService.toggleFavorite(items.first);
                  }
                  Navigator.pop(context);
                }),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Again'),
              onPressed: () {
                setState(() => _scanning = true);
                _ctrl.start();
                Navigator.pop(context);
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Stack(children: [
      MobileScanner(controller: _ctrl, onDetect: _onDetect),

      // Dark overlay with scan window
      CustomPaint(
          painter: _OverlayPainter(),
          child: const SizedBox.expand()),

      // Top controls
      Positioned(
        top: 20, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CtrlBtn(
            icon: _flashOn ? Icons.flash_on : Icons.flash_off,
            label: _flashOn ? 'Flash On' : 'Flash Off',
            onTap: () async {
              await _ctrl.toggleTorch();
              setState(() => _flashOn = !_flashOn);
            },
          ),
          const SizedBox(width: 20),
          _CtrlBtn(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: () => _ctrl.switchCamera(),
          ),
        ]),
      ),

      // Bottom hint
      const Positioned(
        bottom: 48, left: 0, right: 0,
        child: Column(children: [
          Icon(Icons.qr_code_scanner, color: Colors.white54, size: 28),
          SizedBox(height: 8),
          Text('Point camera at QR code or barcode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        ]),
      ),
    ]);
  }
}

// ── Overlay painter ──────────────────────────────────────────
class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const sq = 250.0;
    final l = (size.width - sq) / 2;
    final t = (size.height - sq) / 2;
    final rect = Rect.fromLTWH(l, t, sq, sq);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawPath(
      Path.combine(PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()..addRRect(rrect)),
      Paint()..color = Colors.black54,
    );

    // Corner brackets
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const n = 28.0;

    canvas
      ..drawLine(Offset(l, t + n),      Offset(l, t),          p)
      ..drawLine(Offset(l, t),           Offset(l + n, t),      p)
      ..drawLine(Offset(l + sq - n, t),  Offset(l + sq, t),     p)
      ..drawLine(Offset(l + sq, t),      Offset(l + sq, t + n), p)
      ..drawLine(Offset(l, t + sq - n),  Offset(l, t + sq),     p)
      ..drawLine(Offset(l, t + sq),      Offset(l + n, t + sq), p)
      ..drawLine(Offset(l+sq-n, t+sq),   Offset(l+sq, t+sq),    p)
      ..drawLine(Offset(l+sq, t+sq-n),   Offset(l+sq, t+sq),    p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Widgets ──────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CtrlBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    ),
  );
}

class _ResultAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ResultAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
            color: const Color(0xFF1A3C6E).withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF1A3C6E), size: 24),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]),
  );
}
