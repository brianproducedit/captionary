import 'package:flutter_test/flutter_test.dart';
import 'package:captionary/core/duration_format.dart';

void main() {
  test('formats minutes and seconds', () {
    expect(formatPlayerTime(Duration.zero), '00:00');
    expect(formatPlayerTime(const Duration(minutes: 1, seconds: 5)), '01:05');
  });

  test('includes hours when needed', () {
    expect(
      formatPlayerTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });
}
