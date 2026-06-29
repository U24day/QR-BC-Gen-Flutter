import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class SaveShareSheet extends StatelessWidget {
  final String data;
  final VoidCallback onSave;

  const SaveShareSheet({
    super.key,
    required this.data,
    required this.onSave,
  });

  @override
  Widget build(BuildContext ctx) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _ActionBtn(
          icon: Icons.save_alt_rounded,
          label: 'Save',
          onTap: onSave,
        ),
        _ActionBtn(
          icon: Icons.download_rounded,
          label: 'Gallery',
          onTap: () async {
            try {
              await Gal.requestAccess();
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Saved to gallery')));
            } catch (e) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Error: $e')));
            }
          },
        ),
        _ActionBtn(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: () => Share.share(data),
        ),
        _ActionBtn(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onTap: () {
            Clipboard.setData(ClipboardData(text: data));
            ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')));
          },
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3C6E).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF1A3C6E).withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: const Color(0xFF1A3C6E)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A3C6E))),
        ]),
      ),
    );
  }
}