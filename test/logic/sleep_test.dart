import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/logic/sleep.dart';

void main() {
  test('isSleepDue', () {
    expect(isSleepDue(const SleepAt(1000), 999, 'k', 0), isFalse);
    expect(isSleepDue(const SleepAt(1000), 1000, 'k', 0), isTrue);
    expect(isSleepDue(const SleepAtPosition('k', 100), 0, 'k', 99), isFalse);
    expect(isSleepDue(const SleepAtPosition('k', 100), 0, 'k', 100), isTrue);
    expect(isSleepDue(const SleepAtPosition('k', 100), 0, 'other', 500), isFalse);
    expect(isSleepDue(const SleepItemEnd(), 0, 'k', 0), isFalse);
    expect(isSleepDue(const SleepOff(), 0, 'k', 0), isFalse);
  });

  test('sleepRemaining', () {
    expect(sleepRemaining(const SleepOff(), 0), isNull);
    expect(sleepRemaining(const SleepAt(90000), 0), const SleepMinutesLeft(2));
    expect(sleepRemaining(const SleepAt(10000), 0), const SleepMinutesLeft(1));
    expect(sleepRemaining(const SleepAt(0), 5000), const SleepMinutesLeft(1));
    expect(sleepRemaining(const SleepAtPosition('k', 1), 0), const SleepChapterLeft());
    expect(sleepRemaining(const SleepItemEnd(), 0), const SleepWorkLeft());
  });

  test('sleepAction pauses only audio that was already playing, and clears an expired timer otherwise', () {
    expect(sleepAction(const SleepAt(1000), 999, 'k', 0, true), SleepAction.none);
    expect(sleepAction(const SleepAt(1000), 1000, 'k', 0, true), SleepAction.pause);
    expect(sleepAction(const SleepAt(1000), 5000, 'k', 0, false), SleepAction.clear);
  });

  test('extendSleep adds minutes to a future deadline, counts from now once passed', () {
    expect(extendSleep(const SleepAt(10 * 60000), 5, 0), const SleepAt(15 * 60000));
    expect(extendSleep(const SleepAt(1000), 10, 5000), const SleepAt(5000 + 10 * 60000));
  });

  test('extendSleep leaves non-minute timers unchanged', () {
    expect(extendSleep(const SleepOff(), 5, 0), const SleepOff());
    expect(extendSleep(const SleepAtPosition('k', 100), 5, 0), const SleepAtPosition('k', 100));
    expect(extendSleep(const SleepItemEnd(), 5, 0), const SleepItemEnd());
  });
}
