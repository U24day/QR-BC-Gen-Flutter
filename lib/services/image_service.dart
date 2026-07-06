import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
class ImageService {
  // ── Capture ──────────────────────────────────────────────────────────────

  /// Waits until the current frame (and the next one) are fully painted,
  /// then renders the [RepaintBoundary] at [key] into a PNG [Uint8List].
  ///
  /// Returns null if the key has no context or the capture fails.
  static Future<Uint8List?> captureFromKey(
    GlobalKey key, {
    double pixelRatio = 4.0,
  }) async {
    // Step 1: Wait for any ongoing frame to complete.
    await _waitForFrame();

    // Step 2: Locate the RenderRepaintBoundary.
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject == null) {
      debugPrint('[ImageService] key has no render object — widget not mounted?');
      return null;
    }

    if (renderObject is! RenderRepaintBoundary) {
      debugPrint('[ImageService] render object is not a RenderRepaintBoundary');
      return null;
    }

    final boundary = renderObject;

    // Step 3: If the boundary hasn't been composited into a layer yet,
    // wait one more frame. This happens when QR was just generated (setState).
    if (boundary.debugNeedsPaint) {
      await _waitForFrame();
    }

    // Step 4: Capture.
    try {
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ImageService] toImage() error: $e');
      return null;
    }
  }

  /// Waits for the current frame to finish rendering.
  static Future<void> _waitForFrame() async {
    final Completer<void> completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    // Ensure we are not already between frames (trigger a new one if needed).
    SchedulerBinding.instance.scheduleFrame();
    return completer.future;
  }

  // ── File name ─────────────────────────────────────────────────────────────

  /// Unique file name: QR_20260706_181508.png
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

  /// Captures the widget at [key] and saves it to the device gallery as PNG.
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
        message: '❌ Image capture failed.\nHint: Generate the QR first, then tap Save.',
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
            message: '❌ Storage permission denied.\nPlease allow access in App Settings.',
          );
        }
      }
    } catch (_) {
      // Some Android versions throw here; fall through and let
      // putImageBytes handle it properly.
    }

    // 3. Save
    try {
      final fileName = _uniqueFileName(prefix);
      await Gal.putImageBytes(bytes, name: fileName);
      return ImageResult(
        success: true,
        message: '✅ Saved to gallery!\n$fileName',
      );
    } on GalException catch (e) {
      final msg = switch (e.type) {
        GalExceptionType.accessDenied =>
          '❌ Storage permission denied.\nOpen App Settings to allow access.',
        GalExceptionType.notEnoughSpace =>
          '❌ Not enough storage space.',
        GalExceptionType.notSupportedFormat =>
          '❌ Format not supported on this device.',
        GalExceptionType.unexpected =>
          '❌ Unexpected error: $e',
      };
      return ImageResult(success: false, message: msg);
    } catch (e) {
      return ImageResult(success: false, message: '❌ Save failed: $e');
    }
  }

  // ── Share Image ───────────────────────────────────────────────────────────

  /// Captures the widget at [key] and opens the native share sheet
  /// with the PNG as an image file attachment.
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
        message: '❌ Image capture failed.\nHint: Generate the QR first, then tap Share.',
      );
    }

    // 2. Write to temp file (share_plus requires a file path, not raw bytes)
    try {
      final fileName = _uniqueFileName(prefix);
      final file = await _writeTempFile(bytes, fileName);

      // 3. Open native share sheet with the image file
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        subject: subject ?? 'QR / Barcode Image',
      );

      // Both success and dismissed are acceptable (dismissed = user cancelled)
      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        return const ImageResult(success: true, message: '');
      }
      return const ImageResult(
        success: false,
        message: '❌ Share unavailable on this device.',
      );
    } catch (e) {
      return ImageResult(
        success: false,
        message: '❌ Share failed: $e',
      );
    }
  }
}
