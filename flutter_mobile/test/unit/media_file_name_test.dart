import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/media_file_name.dart';

void main() {
  test('replaces ? and # so ExoPlayer file URIs stay valid', () {
    expect(sanitizeImportedFileName('clip?take#1.mp4'), 'clip_take_1.mp4');
    expect(sanitizeImportedFileName('normal.mp4'), 'normal.mp4');
  });
}
