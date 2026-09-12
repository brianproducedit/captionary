import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SubtitleFileStore {
  SubtitleFileStore({this.directory});

  final Directory? directory;

  Future<File> write({
    required String fileName,
    required String content,
  }) async {
    final dir = directory ?? await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(content);
    return file;
  }
}

class CaptionShareRequest {
  final String path;
  final String mimeType;
  final String fileName;

  const CaptionShareRequest({
    required this.path,
    required this.mimeType,
    required this.fileName,
  });
}

typedef CaptionShareHandler = Future<void> Function(CaptionShareRequest request);
