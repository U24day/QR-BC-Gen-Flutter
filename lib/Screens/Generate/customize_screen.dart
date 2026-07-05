import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CustomizeScreen extends StatefulWidget {
  final Color fgColor, bgColor;
  final double size;
  final int margin, eccLevel;
  final void Function(Color fg, Color bg, double sz, int mg, int ecc) onApply;

  const CustomizeScreen({
    super.key,
    required this.fgColor,
    required this.bgColor,
    required this.size,
    required this.margin,
    required this.eccLevel,
    required this.onApply,
  });

  @override
  State<CustomizeScreen> createState() => _CustomizeState();
}

class _CustomizeState extends State<CustomizeScreen> {
  late Color _fg, _bg;
  late double _size;
  late int _margin, _ecc;

  @override
  void initState() {
    super.initState();
    _fg     = widget.fgColor;
    _bg     = widget.bgColor;
    _size   = widget.size;
    _margin = widget.margin;
    _ecc    = widget.eccLevel;
  }

  void _pickColor(bool fg) {
    Color tmp = fg ? _fg : _bg;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(fg ? 'QR Color' : 'Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tmp,
            onColorChanged: (c) => tmp = c,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C6E),
                foregroundColor: Colors.white),
            child: const Text('Apply'),
            onPressed: () {
              setState(() {
                if (fg) {
                  _fg = tmp;
                } else {
                  _bg = tmp;
                }
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customize QR Code')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Live preview
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12, offset: const Offset(0, 4))]),
              child: QrImageView(
                data: 'https://example.com',
                version: QrVersions.auto,
                size: _size,
                eyeStyle: QrEyeStyle(color: _fg),
                dataModuleStyle: QrDataModuleStyle(color: _fg),
                backgroundColor: _bg,
                gapless: true,
                errorCorrectionLevel: _ecc,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Colors
          const Text('Colors',
              style: TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 16, color: Color(0xFF1A3C6E))),
          const SizedBox(height: 10),
          Row(children: [
            _ColorBtn(label: 'QR Color',   color: _fg, onTap: () => _pickColor(true)),
            const SizedBox(width: 12),
            _ColorBtn(label: 'Background', color: _bg, onTap: () => _pickColor(false)),
          ]),
          const SizedBox(height: 24),

          // Size
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Size',
                style: TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 16, color: Color(0xFF1A3C6E))),
            Text('${_size.round()} px',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
          Slider(
            value: _size, min: 100, max: 400, divisions: 30,
            activeColor: const Color(0xFF1A3C6E),
            onChanged: (v) => setState(() => _size = v),
          ),
          const SizedBox(height: 8),

          // Margin
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Margin',
                style: TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 16, color: Color(0xFF1A3C6E))),
            Text('$_margin',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
          Slider(
            value: _margin.toDouble(), min: 0, max: 10, divisions: 10,
            activeColor: const Color(0xFF1A3C6E),
            onChanged: (v) => setState(() => _margin = v.round()),
          ),
          const SizedBox(height: 16),

          // Error correction
          const Text('Error Correction Level',
              style: TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 16, color: Color(0xFF1A3C6E))),
          const SizedBox(height: 6),
          Text(
            'L = 7%   M = 15%   Q = 25%   H = 30% recovery',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: QrErrorCorrectLevel.L, label: Text('L')),
              ButtonSegment(value: QrErrorCorrectLevel.M, label: Text('M')),
              ButtonSegment(value: QrErrorCorrectLevel.Q, label: Text('Q')),
              ButtonSegment(value: QrErrorCorrectLevel.H, label: Text('H')),
            ],
            selected: {_ecc},
            onSelectionChanged: (s) => setState(() => _ecc = s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? const Color(0xFF1A3C6E) : null),
              foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? Colors.white : null),
            ),
          ),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Apply Changes',
                  style: TextStyle(fontSize: 16)),
              onPressed: () {
                widget.onApply(_fg, _bg, _size, _margin, _ecc);
                Navigator.pop(ctx);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _ColorBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ColorBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext ctx) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300)),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  );
}