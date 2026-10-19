import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MediaScannerService {
  static const MethodChannel _channel = MethodChannel(
    'com.captionary.captionary/system_memory',
  );

  /// Requests the Android MediaScanner to index [filePath] so it immediately
  /// appears in Gallery, Photos, and Media file pickers.
  static Future<void> scanFile(String filePath) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      debugPrint('[MediaScannerService] Failed to scan file: $e');
    }
  }
}
