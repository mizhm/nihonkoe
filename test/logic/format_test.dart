import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/format.dart';

void main() {
  test('formatTime', () {
    expect(formatTime(0), '0:00');
    expect(formatTime(65.9), '1:05');
    expect(formatTime(3725), '1:02:05');
    expect(formatTime(-3), '0:00');
    expect(formatTime(double.nan), '0:00');
  });
}
