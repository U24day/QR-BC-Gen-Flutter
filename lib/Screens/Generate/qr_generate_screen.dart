import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'customize_screen.dart';
import '../../Widgets/save_share_sheet.dart';
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

  // RepaintBoundary key — used by SaveShareSheet to capture the QR image.
  final GlobalKey _qrKey = GlobalKey();

  final _textCtrl  = TextEditingController();
  final _urlCtrl   = TextEditingController();
  final _ssidCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _smsNum    = TextEditingController();
  final _smsMsg    = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _emailSub  = TextEditingController();
  final _emailBody = TextEditingController();
  final _latCtrl   = TextEditingController();
  final _lngCtrl   = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _orgCtrl   = TextEditingController();
  final _vcPhone   = TextEditingController();
  final _vcEmail   = TextEditingController();

  Color _fgColor  = Colors.black;
  Color _bgColor  = Colors.white;
  double _size    = 220;
  int _margin     = 4;
  int _eccLevel   = QrErrorCorrectLevel.M;
  String _wifiEnc = 'WPA';

  // Validation error message shown to user.
  String? _validationError;

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

  @override
  void dispose() {
    for (final c in [
      _textCtrl, _urlCtrl, _ssidCtrl, _passCtrl, _phoneCtrl,
      _smsNum, _smsMsg, _emailCtrl, _emailSub, _emailBody,
      _latCtrl, _lngCtrl, _nameCtrl, _orgCtrl, _vcPhone, _vcEmail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────

  String? _validate() {
    switch (_type) {
      case QrType.text:
        if (_textCtrl.text.trim().isEmpty) return 'Please enter some text.';
      case QrType.url:
        if (_urlCtrl.text.trim().isEmpty) return 'Please enter a URL.';
      case QrType.wifi:
        if (_ssidCtrl.text.trim().isEmpty) return 'SSID (network name) is required.';
      case QrType.phone:
        if (_phoneCtrl.text.trim().isEmpty) return 'Please enter a phone number.';
      case QrType.sms:
        if (_smsNum.text.trim().isEmpty) return 'Please enter a phone number.';
        if (_smsMsg.text.trim().isEmpty) return 'Please enter a message.';
      case QrType.email:
        if (_emailCtrl.text.trim().isEmpty) return 'Please enter an email address.';
        final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailReg.hasMatch(_emailCtrl.text.trim())) {
          return 'Enter a valid email address.';
        }
      case QrType.location:
        if (_latCtrl.text.trim().isEmpty || _lngCtrl.text.trim().isEmpty) {
          return 'Please enter both Latitude and Longitude.';
        }
        final lat = double.tryParse(_latCtrl.text.trim());
        final lng = double.tryParse(_lngCtrl.text.trim());
        if (lat == null || lng == null) return 'Latitude and Longitude must be numbers.';
        if (lat < -90 || lat > 90) return 'Latitude must be between -90 and 90.';
        if (lng < -180 || lng > 180) return 'Longitude must be between -180 and 180.';
      case QrType.vcard:
        if (_nameCtrl.text.trim().isEmpty) return 'Name is required for vCard.';
    }
    return null;
  }

  // ── Build QR data string ────────────────────────────────────────────────

  void _buildData() {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final error = _validate();
    if (error != null) {
      setState(() {
        _validationError = error;
        _qrData = '';
      });
      return;
    }

    String d = '';
    switch (_type) {
      case QrType.text:
        d = _textCtrl.text.trim();
      case QrType.url:
        final raw = _urlCtrl.text.trim();
        d = raw.startsWith('http') ? raw : 'https://$raw';
      case QrType.wifi:
        d = 'WIFI:T:$_wifiEnc;S:${_ssidCtrl.text.trim()};P:${_passCtrl.text};;';
      case QrType.phone:
        d = 'tel:${_phoneCtrl.text.trim()}';
      case QrType.sms:
        d = 'smsto:${_smsNum.text.trim()}:${_smsMsg.text.trim()}';
      case QrType.email:
        d = 'mailto:${_emailCtrl.text.trim()}'
            '?subject=${Uri.encodeComponent(_emailSub.text.trim())}'
            '&body=${Uri.encodeComponent(_emailBody.text.trim())}';
      case QrType.location:
        d = 'geo:${_latCtrl.text.trim()},${_lngCtrl.text.trim()}';
      case QrType.vcard:
        d = 'BEGIN:VCARD\nVERSION:3.0\nFN:${_nameCtrl.text.trim()}\n'
            'ORG:${_orgCtrl.text.trim()}\nTEL:${_vcPhone.text.trim()}\n'
            'EMAIL:${_vcEmail.text.trim()}\nEND:VCARD';
    }
    setState(() {
      _qrData = d;
      _validationError = null;
    });
  }

  // ── Save to Hive history ────────────────────────────────────────────────

  Future<void> _saveHistory() async {
    if (_qrData.isEmpty) return;
    final item = CodeItem(
      type: 'qr',
      subtype: _type.name,
      data: _qrData,
      label: _qrData.length > 40 ? '${_qrData.substring(0, 40)}…' : _qrData,
      isGenerated: true,
    );
    await historyService.add(item);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved to history ✓'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Input field decoration ──────────────────────────────────────────────

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );

  // ── Input fields per QR type ────────────────────────────────────────────

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
            initialValue: _wifiEnc,
            decoration: _dec('Encryption'),
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

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Type chips ──────────────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
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
                    _validationError = null;
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // ── Input card ──────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _types.firstWhere((t) => t.$1 == _type).$3,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E)),
                ),
                const SizedBox(height: 10),
                _buildFields(),

                // Validation error message
                if (_validationError != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ]),
                ],

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

        // ── QR Preview ──────────────────────────────────────────────────
        if (_qrData.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // RepaintBoundary captures exactly this widget for image export.
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      color: _bgColor,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: _size,
                        eyeStyle: QrEyeStyle(color: _fgColor),
                        dataModuleStyle: QrDataModuleStyle(color: _fgColor),
                        backgroundColor: _bgColor,
                        gapless: true,
                        errorCorrectionLevel: _eccLevel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _qrData,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Action buttons (Save to History / Gallery / Share / Copy)
                  SaveShareSheet(
                    data: _qrData,
                    repaintKey: _qrKey,
                    onSaveHistory: _saveHistory,
                    prefix: 'QR',
                  ),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}