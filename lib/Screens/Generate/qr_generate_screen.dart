import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'customize_screen.dart';
import '../../widgets/save_share_sheet.dart';
import '../../models/code_item.dart';
import '../../main.dart';

enum QrType { text, url, wifi, phone, sms, email, location, vcard }

class QrGenerateScreen extends StatefulWidget {
  const QrGenerateScreen({super.key});
  @override
  State<QrGenerateScreen> createState() => _QrGenState();
}

class _QrGenState extends State<QrGenerateScreen> {
  QrType _type = QrType.text;
  String _qrData = '';

  final _textCtrl   = TextEditingController();
  final _urlCtrl    = TextEditingController();
  final _ssidCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _smsNum     = TextEditingController();
  final _smsMsg     = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _emailSub   = TextEditingController();
  final _emailBody  = TextEditingController();
  final _latCtrl    = TextEditingController();
  final _lngCtrl    = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _orgCtrl    = TextEditingController();
  final _vcPhone    = TextEditingController();
  final _vcEmail    = TextEditingController();

  Color _fgColor  = Colors.black;
  Color _bgColor  = Colors.white;
  double _size    = 200;
  int _margin     = 4;
  int _eccLevel   = QrErrorCorrectLevel.M;
  String _wifiEnc = 'WPA';

  static const _types = [
    (QrType.text,     Icons.text_fields,  'Text'),
    (QrType.url,      Icons.link,         'URL'),
    (QrType.wifi,     Icons.wifi,         'WiFi'),
    (QrType.phone,    Icons.phone,        'Phone'),
    (QrType.sms,      Icons.sms,          'SMS'),
    (QrType.email,    Icons.email,        'Email'),
    (QrType.location, Icons.location_on,  'Location'),
    (QrType.vcard,    Icons.contact_page, 'vCard'),
  ];

  void _buildData() {
    String d = '';
    switch (_type) {
      case QrType.text:
        d = _textCtrl.text;
      case QrType.url:
        d = _urlCtrl.text.startsWith('http')
            ? _urlCtrl.text : 'https://${_urlCtrl.text}';
      case QrType.wifi:
        d = 'WIFI:T:$_wifiEnc;S:${_ssidCtrl.text};P:${_passCtrl.text};;';
      case QrType.phone:
        d = 'tel:${_phoneCtrl.text}';
      case QrType.sms:
        d = 'smsto:${_smsNum.text}:${_smsMsg.text}';
      case QrType.email:
        d = 'mailto:${_emailCtrl.text}'
            '?subject=${_emailSub.text}&body=${_emailBody.text}';
      case QrType.location:
        d = 'geo:${_latCtrl.text},${_lngCtrl.text}';
      case QrType.vcard:
        d = 'BEGIN:VCARD\nVERSION:3.0\nFN:${_nameCtrl.text}\n'
            'ORG:${_orgCtrl.text}\nTEL:${_vcPhone.text}\n'
            'EMAIL:${_vcEmail.text}\nEND:VCARD';
    }
    setState(() => _qrData = d);
  }

  Future<void> _save() async {
    if (_qrData.isEmpty) return;
    final item = CodeItem(
      type: 'qr', subtype: _type.name, data: _qrData,
      label: _qrData.length > 40
          ? '${_qrData.substring(0, 40)}…' : _qrData,
      isGenerated: true,
    );
    await historyService.add(item);
    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved to history')));
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    border: const OutlineInputBorder(),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );

  Widget _buildFields() {
    switch (_type) {
      case QrType.text:
        return TextField(controller: _textCtrl,
            decoration: _dec('Enter text'), maxLines: 3);
      case QrType.url:
        return TextField(controller: _urlCtrl,
            decoration: _dec('https://example.com'),
            keyboardType: TextInputType.url);
      case QrType.wifi:
        return Column(children: [
          TextField(controller: _ssidCtrl,
              decoration: _dec('Network name (SSID)')),
          const SizedBox(height: 8),
          TextField(controller: _passCtrl,
              decoration: _dec('Password'), obscureText: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _wifiEnc, decoration: _dec('Encryption'),
            items: ['WPA', 'WEP', 'nopass'].map((e) =>
                DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _wifiEnc = v!),
          ),
        ]);
      case QrType.phone:
        return TextField(controller: _phoneCtrl,
            decoration: _dec('+1 555 000 0000'),
            keyboardType: TextInputType.phone);
      case QrType.sms:
        return Column(children: [
          TextField(controller: _smsNum,
              decoration: _dec('Phone number'),
              keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          TextField(controller: _smsMsg,
              decoration: _dec('Message'), maxLines: 2),
        ]);
      case QrType.email:
        return Column(children: [
          TextField(controller: _emailCtrl,
              decoration: _dec('recipient@email.com'),
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 8),
          TextField(controller: _emailSub, decoration: _dec('Subject')),
          const SizedBox(height: 8),
          TextField(controller: _emailBody,
              decoration: _dec('Body'), maxLines: 2),
        ]);
      case QrType.location:
        return Row(children: [
          Expanded(child: TextField(controller: _latCtrl,
              decoration: _dec('Latitude'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _lngCtrl,
              decoration: _dec('Longitude'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]);
      case QrType.vcard:
        return Column(children: [
          TextField(controller: _nameCtrl, decoration: _dec('Full name')),
          const SizedBox(height: 8),
          TextField(controller: _orgCtrl, decoration: _dec('Organization')),
          const SizedBox(height: 8),
          TextField(controller: _vcPhone, decoration: _dec('Phone'),
              keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          TextField(controller: _vcEmail, decoration: _dec('Email'),
              keyboardType: TextInputType.emailAddress),
        ]);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type chips
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal,
            children: _types.map((t) {
              final sel = _type == t.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(t.$2, size: 16,
                      color: sel ? Colors.white : const Color(0xFF1A3C6E)),
                  label: Text(t.$3,
                      style: TextStyle(fontSize: 13,
                          color: sel ? Colors.white : const Color(0xFF1A3C6E))),
                  selected: sel,
                  selectedColor: const Color(0xFF1A3C6E),
                  onSelected: (_) => setState(() {
                    _type = t.$1;
                    _qrData = '';
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Input card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_types.firstWhere((t) => t.$1 == _type).$3,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3C6E))),
                const SizedBox(height: 10),
                _buildFields(),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3C6E),
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Generate'),
                      onPressed: _buildData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Customize'),
                    onPressed: () => Navigator.push(ctx,
                      MaterialPageRoute(builder: (_) => CustomizeScreen(
                        fgColor: _fgColor, bgColor: _bgColor,
                        size: _size, margin: _margin, eccLevel: _eccLevel,
                        onApply: (fg, bg, sz, mg, ecc) => setState(() {
                          _fgColor = fg; _bgColor = bg;
                          _size = sz; _margin = mg; _eccLevel = ecc;
                        }),
                      )),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // Preview
        if (_qrData.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: _size,
                    eyeStyle: QrEyeStyle(color: _fgColor),
                    dataModuleStyle: QrDataModuleStyle(color: _fgColor),
                    backgroundColor: _bgColor,
                    gapless: true,
                    errorCorrectionLevel: _eccLevel,
                  ),
                  const SizedBox(height: 10),
                  Text(_qrData,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  SaveShareSheet(data: _qrData, onSave: _save),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}