import '../l10n/app_localizations.dart';
import '../logic/sleep.dart';

String sleepText(SleepRemaining remaining, AppLocalizations l) => switch (remaining) {
      SleepMinutesLeft(:final minutes) => l.sleepMinutes(minutes),
      SleepChapterLeft() => l.sleepRemainingChapter,
      SleepWorkLeft() => l.sleepRemainingWork,
    };
