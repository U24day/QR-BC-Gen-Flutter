import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../Widgets/save_share_sheet.dart';
import '../../models/code_item.dart';
import '../../main.dart';

class BarcodeGenerateScreen extends StatefulWidget {
  const BarcodeGenerateScreen({super.key});
  @override
  State<BarcodeGenerateScreen> createState() => _BarcodeGenState();
}

class _BarcodeGenState extends State<BarcodeGenerateScreen> {
  final _ctrl = TextEditingController();
  String _data = '';
  BarcodeType _barcodeType = BarcodeType.Code128;
  final Color _fg = Colors.black;
  final Color _bg = Colors.white;

  static const _types = [
    (BarcodeType.Code128,    'Code 128',    'Alphanumeric, any length'),
    (BarcodeType.Code39,     'Code 39',     'Uppercase + digits'),
    (BarcodeType.CodeEAN13,  'EAN-13',      '13 digits'),
    (BarcodeType.CodeEAN8,   'EAN-8',       '8 digits'),
    (BarcodeType.CodeUPCA,   'UPC-A',       '12 digits'),
    (BarcodeType.CodeUPCE,   'UPC-E',       '8 digits'),
    (BarcodeType.CodeITF14,  'ITF-14',      'Even number of digits'),
    (BarcodeType.PDF417,     'PDF417',      '2D stacked barcode'),
    (BarcodeType.DataMatrix, 'Data Matrix', '2D compact square'),
    (BarcodeType.Aztec,      'Aztec',       '2D concentric rings'),
  ];

  bool get _isNumeric =>
      _barcodeType == BarcodeType.CodeEAN13 ||
          _barcodeType == BarcodeType.CodeEAN8  ||
          _barcodeType == BarcodeType.CodeUPCA  ||
          _barcodeType == BarcodeType.CodeUPCE  ||
          _barcodeType == BarcodeType.CodeITF14;

  Future<void> _save() async {
    if (_data.isEmpty) return;
    final item = CodeItem(
      type: 'barcode',
      subtype: _barcodeType.name,
      data: _data,
      label: _data,
      isGenerated: true,
    );
    await historyService.add(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to history')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barcode type list
          Card(
            child: RadioGroup<BarcodeType>(
              groupValue: _barcodeType,
              onChanged: (v) => setState(() {
                if (v != null) {
                  _barcodeType = v;
                  _data = '';
                  _ctrl.clear();
                }
              }),
              child: Column(
                children: _types.map((t) => RadioListTile<BarcodeType>(
                  value: t.$1,
                  title: Text(t.$2, style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text(t.$3,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  activeColor: const Color(0xFF1A3C6E),
                  dense: true,
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Input
          TextField(
            controller: _ctrl,
            keyboardType: _isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Enter data for barcode',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _ctrl.clear();
                  setState(() => _data = '');
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.barcode_reader),
              label: const Text('Generate Barcode',
                  style: TextStyle(fontSize: 15)),
              onPressed: () => setState(() => _data = _ctrl.text.trim()),
            ),
          ),

          // Preview
          if (_data.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.fromType(_barcodeType),
                      data: _data,
                      width: double.infinity,
                      height: 120,
                      color: _fg,
                      backgroundColor: _bg,
                      drawText: true,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Text(_data,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    SaveShareSheet(data: _data, onSave: _save),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
