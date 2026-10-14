import '../api/models.dart';

/// Within this many seconds of a chapter's start, "previous" goes to the chapter (or item) before.
const restartThresholdSeconds = 3;

int chapterIndexAt(List<Track> chapters, double position) {
  var index = -1;
  for (var i = 0; i < chapters.length && chapters[i].startSeconds <= position; i++) {
    index = i;
  }
  return index;
}

double previousChapterStart(List<Track> chapters, double position) {
  final index = chapterIndexAt(chapters, position);
  if (index < 0) return 0;
  final start = chapters[index].startSeconds.toDouble();
  if (index == 0 || position - start > restartThresholdSeconds) return start;
  return chapters[index - 1].startSeconds.toDouble();
}

double? nextChapterStart(List<Track> chapters, double position) {
  final next = chapterIndexAt(chapters, position) + 1;
  return next < chapters.length ? chapters[next].startSeconds.toDouble() : null;
}
