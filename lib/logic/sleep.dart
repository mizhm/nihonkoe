sealed class SleepTimer {
  const SleepTimer();
}

class SleepOff extends SleepTimer {
  const SleepOff();
  @override
  bool operator ==(Object other) => other is SleepOff;
  @override
  int get hashCode => 0;
}

class SleepAt extends SleepTimer {
  const SleepAt(this.deadline);
  final int deadline; // epoch milliseconds
  @override
  bool operator ==(Object other) => other is SleepAt && other.deadline == deadline;
  @override
  int get hashCode => deadline.hashCode;
  @override
  String toString() => 'SleepAt($deadline)';
}

/// Stops when stream [key] reaches [seconds] — "end of this chapter".
class SleepAtPosition extends SleepTimer {
  const SleepAtPosition(this.key, this.seconds);
  final String key;
  final double seconds;
  @override
  bool operator ==(Object other) => other is SleepAtPosition && other.key == key && other.seconds == seconds;
  @override
  int get hashCode => Object.hash(key, seconds);
  @override
  String toString() => 'SleepAtPosition($key, $seconds)';
}

/// Stops when the current work's last stream ends.
class SleepItemEnd extends SleepTimer {
  const SleepItemEnd();
  @override
  bool operator ==(Object other) => other is SleepItemEnd;
  @override
  int get hashCode => 1;
}

bool isSleepDue(SleepTimer timer, int now, String key, double position) => switch (timer) {
      SleepAt(:final deadline) => now >= deadline,
      SleepAtPosition(key: final k, :final seconds) => key == k && position >= seconds,
      _ => false,
    };

enum SleepAction { none, pause, clear }

/// A timer can expire unseen while paused; it must not pause the next resume.
SleepAction sleepAction(SleepTimer timer, int now, String key, double position, bool wasPlaying) {
  if (!isSleepDue(timer, now, key, position)) return SleepAction.none;
  return wasPlaying ? SleepAction.pause : SleepAction.clear;
}

sealed class SleepRemaining {
  const SleepRemaining();
}

class SleepMinutesLeft extends SleepRemaining {
  const SleepMinutesLeft(this.minutes);
  final int minutes;
  @override
  bool operator ==(Object other) => other is SleepMinutesLeft && other.minutes == minutes;
  @override
  int get hashCode => minutes.hashCode;
  @override
  String toString() => 'SleepMinutesLeft($minutes)';
}

class SleepChapterLeft extends SleepRemaining {
  const SleepChapterLeft();
  @override
  bool operator ==(Object other) => other is SleepChapterLeft;
  @override
  int get hashCode => 2;
}

class SleepWorkLeft extends SleepRemaining {
  const SleepWorkLeft();
  @override
  bool operator ==(Object other) => other is SleepWorkLeft;
  @override
  int get hashCode => 3;
}

SleepRemaining? sleepRemaining(SleepTimer timer, int now) => switch (timer) {
      SleepOff() => null,
      SleepAt(:final deadline) => SleepMinutesLeft(((deadline - now) / 60000).ceil().clamp(1, 1 << 30)),
      SleepAtPosition() => const SleepChapterLeft(),
      SleepItemEnd() => const SleepWorkLeft(),
    };

const sleepMinutes = [5, 10, 15, 30, 60, 90];
const sleepExtend = [5, 10, 30];

/// Only minute timers can be extended; an expired deadline extends from now.
SleepTimer extendSleep(SleepTimer timer, int minutes, int now) => switch (timer) {
      SleepAt(:final deadline) => SleepAt((deadline > now ? deadline : now) + minutes * 60000),
      _ => timer,
    };
