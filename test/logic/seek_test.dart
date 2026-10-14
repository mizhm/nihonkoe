import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/seek.dart';

void main() {
  test('seekTarget maps a touch x to seconds across the bar', () {
    expect(seekTarget(150, 300, 600), 300);
    expect(seekTarget(0, 300, 600), 0);
    expect(seekTarget(300, 300, 600), 600);
  });

  test('seekTarget clamps touches past either end', () {
    expect(seekTarget(-20, 300, 600), 0);
    expect(seekTarget(420, 300, 600), 600);
  });

  test('seekTarget stays at 0 before layout or duration are known', () {
    expect(seekTarget(100, 0, 600), 0);
    expect(seekTarget(100, 300, 0), 0);
  });
}
