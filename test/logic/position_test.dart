import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/position.dart';

void main() {
  test('shouldSavePosition: every 5 s while playing, on any real change while paused', () {
    expect(shouldSavePosition(true, 104, 100), isFalse);
    expect(shouldSavePosition(true, 105, 100), isTrue);
    expect(shouldSavePosition(false, 102, 100), isTrue);
    expect(shouldSavePosition(false, 100.4, 100), isFalse);
  });

  test('resumeTarget restarts works that were left in their last seconds', () {
    expect(resumeTarget(120, 3600), 120);
    expect(resumeTarget(3595, 3600), 0);
    expect(resumeTarget(50, 0), 50);
  });

  test('stopPosition keeps a pending resume seek, saves the current time otherwise, nothing after the end', () {
    expect(stopPosition(1800, 0, false), 1800);
    expect(stopPosition(null, 754, false), 754);
    expect(stopPosition(null, 3720, true), isNull);
  });

  test('inProgressPosition prefers the first stream, then any later one, ignoring zeros and other works', () {
    expect(inProgressPosition({'5:0': 120, '5:1': 30}, 5), 120);
    expect(inProgressPosition({'5:1': 30, '50:0': 99}, 5), 30);
    expect(inProgressPosition({'50:0': 99, '5:0': 0}, 5), isNull);
    expect(inProgressPosition({}, 5), isNull);
  });
}
