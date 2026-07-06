import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';

/// A row of action buttons shown below a generated QR code or barcode.
///
/// Pass the [repaintKey] of the [RepaintBoundary] wrapping the code widget
/// so that Gallery, Share, and Copy Image buttons can capture the actual image.
///
/// [onSaveHistory] — saves item to Hive history.
/// [prefix] — file name prefix ("QR" or "Barcode").
/// [data] — used only for the "Copy Text" action.
class SaveShareSheet extends StatefulWidget {
  final String data;
  final GlobalKey repaintKey;
  final VoidCallback onSaveHistory;
  final String prefix;

  const SaveShareSheet({
    super.key,
    required this.data,
    required this.repaintKey,
    required this.onSaveHistory,
    this.prefix = 'QR',
  });

  @override
  State<SaveShareSheet> createState() => _SaveShareSheetState();
}

class _SaveShareSheetState extends State<SaveShareSheet> {
  bool _savingGallery  = false;
  bool _sharing        = false;
  bool _copyingImage   = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Save item to Hive history.
  void _saveToHistory() => widget.onSaveHistory();

  /// Save QR/Barcode as PNG to device gallery.
  Future<void> _saveToGallery() async {
    if (_savingGallery) return;
    setState(() => _savingGallery = true);
    try {
      final result = await ImageService.saveToGallery(
        widget.repaintKey,
        prefix: widget.prefix,
        pixelRatio: 4.0,
      );
      _showSnack(result.message, isError: !result.success);
    } catch (e) {
      _showSnack('❌ Gallery save error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingGallery = false);
    }
  }

  /// Open native share sheet with actual image file.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final result = await ImageService.shareImage(
        widget.repaintKey,
        prefix: widget.prefix,
        pixelRatio: 4.0,
      );
      if (!result.success) {
        _showSnack(result.message, isError: true);
      }
    } catch (e) {
      _showSnack('❌ Share error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Copy QR/Barcode image (PNG) to system clipboard.
  Future<void> _copyImage() async {
    if (_copyingImage) return;
    setState(() => _copyingImage = true);
    try {
      final result = await ImageService.copyImageToClipboard(
        widget.repaintKey,
        pixelRatio: 4.0,
      );
      _showSnack(result.message, isError: !result.success);
    } catch (e) {
      _showSnack('❌ Copy image error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _copyingImage = false);
    }
  }

  /// Copy the underlying data text (URL/message) to clipboard.
  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.data));
    _showSnack('📋 Text copied to clipboard');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        // Save to History
        _ActionBtn(
          icon: Icons.bookmark_add_outlined,
          label: 'History',
          onTap: _saveToHistory,
        ),

        // Save to Gallery (PNG file)
        _ActionBtn(
          icon: Icons.download_rounded,
          label: 'Gallery',
          isLoading: _savingGallery,
          onTap: _saveToGallery,
        ),

        // Share image via native share sheet
        _ActionBtn(
          icon: Icons.share_rounded,
          label: 'Share',
          isLoading: _sharing,
          onTap: _share,
        ),

        // Copy image to clipboard
        _ActionBtn(
          icon: Icons.image_outlined,
          label: 'Copy Image',
          isLoading: _copyingImage,
          onTap: _copyImage,
        ),

        // Copy text/URL to clipboard
        _ActionBtn(
          icon: Icons.copy_rounded,
          label: 'Copy Text',
          onTap: _copyText,
        ),
      ],
    );
  }
}

// ── Private button widget ─────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  static const _primary = Color(0xFF1A3C6E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              )
            else
              Icon(icon, size: 18, color: _primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _primary,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}