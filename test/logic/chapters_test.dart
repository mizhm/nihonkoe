import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/logic/chapters.dart';

const chapters = [Track(title: 'a', startSeconds: 0), Track(title: 'b', startSeconds: 100), Track(title: 'c', startSeconds: 250)];

void main() {
  test('chapterIndexAt', () {
    expect(chapterIndexAt(chapters, 0), 0);
    expect(chapterIndexAt(chapters, 99.9), 0);
    expect(chapterIndexAt(chapters, 100), 1);
    expect(chapterIndexAt(chapters, 9999), 2);
    expect(chapterIndexAt(const [], 5), -1);
    expect(chapterIndexAt(const [Track(title: 'late', startSeconds: 5)], 2), -1);
  });

  test('previousChapterStart restarts the chapter unless near its start', () {
    expect(previousChapterStart(chapters, 150), 100);
    expect(previousChapterStart(chapters, 101), 0);
    expect(previousChapterStart(chapters, 2), 0);
    expect(previousChapterStart(const [], 50), 0);
  });

  test('nextChapterStart', () {
    expect(nextChapterStart(chapters, 150), 250);
    expect(nextChapterStart(chapters, 300), isNull);
    expect(nextChapterStart(const [], 0), isNull);
  });
}
