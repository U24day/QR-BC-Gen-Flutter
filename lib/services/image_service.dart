import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result returned by [ImageService] operations.
class ImageResult {
  final bool success;
  final String message;
  final String? filePath;

  const ImageResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

/// Central service for capturing, saving, and sharing QR / Barcode images.
///
/// Usage:
///   1. Wrap your QrImageView / BarcodeWidget in a [RepaintBoundary] and
///      assign a [GlobalKey].
///   2. Pass that key to [saveToGallery] or [shareImage].
class ImageService {
  // ── Capture ──────────────────────────────────────────────────────────────

  /// Renders the widget bound to [key] into a high-resolution [Uint8List] PNG.
  ///
  /// [pixelRatio] 4.0 → ~512 px on a 128-px widget, 8.0 → ~1024 px, etc.
  static Future<Uint8List?> captureFromKey(
    GlobalKey key, {
    double pixelRatio = 4.0,
  }) async {
    try {
      final boundary = key.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Wait for any pending layout / paint passes.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ImageService] capture error: $e');
      return null;
    }
  }

  // ── File name ─────────────────────────────────────────────────────────────

  /// Unique file name like  QR_20260706_181508.png
  static String _uniqueFileName(String prefix) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_p(now.month)}${_p(now.day)}_'
        '${_p(now.hour)}${_p(now.minute)}${_p(now.second)}';
    return '${prefix}_$stamp.png';
  }

  static String _p(int v) => v.toString().padLeft(2, '0');

  // ── Temp file ─────────────────────────────────────────────────────────────

  /// Writes [bytes] to a temp file and returns its [File].
  static Future<File> _writeTempFile(
      Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // ── Save to Gallery ───────────────────────────────────────────────────────

  /// Captures the widget at [key] and saves it to the device gallery.
  ///
  /// Returns an [ImageResult] with [success] and a user-facing [message].
  static Future<ImageResult> saveToGallery(
    GlobalKey key, {
    String prefix = 'QR',
    double pixelRatio = 4.0,
  }) async {
    // 1. Capture
    final bytes = await captureFromKey(key, pixelRatio: pixelRatio);
    if (bytes == null) {
      return const ImageResult(
        success: false,
        message: 'Image capture failed. Please try again.',
      );
    }

    // 2. Request gallery permission via gal
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          return const ImageResult(
            success: false,
            message:
                'Storage permission denied. Please allow it in App Settings.',
          );
        }
      }
    } catch (_) {
      // gal throws on some Android versions — fall through and let
      // putImageBytes raise a proper error.
    }

    // 3. Save
    try {
      final fileName = _uniqueFileName(prefix);
      await Gal.putImageBytes(bytes, name: fileName);
      return ImageResult(
        success: true,
        message: 'Saved to gallery as $fileName ✓',
      );
    } on GalException catch (e) {
      final msg = switch (e.type) {
        GalExceptionType.accessDenied =>
          'Storage permission denied. Open App Settings to allow access.',
        GalExceptionType.notEnoughSpace =>
          'Not enough storage space.',
        GalExceptionType.notSupportedFormat =>
          'This format is not supported on your device.',
        GalExceptionType.unexpected =>
          'Unexpected error while saving: $e',
      };
      return ImageResult(success: false, message: msg);
    } catch (e) {
      return ImageResult(
        success: false,
        message: 'Save failed: $e',
      );
    }
  }

  // ── Share Image ───────────────────────────────────────────────────────────

  /// Captures the widget at [key] and opens the native share sheet with
  /// the PNG as an [XFile] attachment.
  ///
  /// Returns an [ImageResult] describing what happened.
  static Future<ImageResult> shareImage(
    GlobalKey key, {
    String prefix = 'QR',
    String? subject,
    double pixelRatio = 4.0,
  }) async {
    // 1. Capture
    final bytes = await captureFromKey(key, pixelRatio: pixelRatio);
    if (bytes == null) {
      return const ImageResult(
        success: false,
        message: 'Image capture failed. Please try again.',
      );
    }

    // 2. Write to temp file (share_plus needs a real file path)
    try {
      final fileName = _uniqueFileName(prefix);
      final file = await _writeTempFile(bytes, fileName);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        subject: subject ?? 'QR / Barcode Image',
      );

      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        // Both are OK — dismissed just means user cancelled.
        return const ImageResult(success: true, message: 'Share sheet opened');
      }
      return const ImageResult(
        success: false,
        message: 'Share was unavailable on this device.',
      );
    } catch (e) {
      return ImageResult(
        success: false,
        message: 'Share failed: $e',
      );
    }
  }
}
