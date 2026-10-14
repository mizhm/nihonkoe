import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/state/library.dart';

void main() {
  test('todayProvider moves to the next day at midnight', () {
    fakeAsync((async) {
      var now = DateTime(2026, 10, 14, 23, 59, 30);
      final c = ProviderContainer.test(overrides: [clockProvider.overrideWithValue(() => now)]);
      final seen = <DateTime>[];
      c.listen(todayProvider, (_, next) => seen.add(next), fireImmediately: true);
      expect(seen.single, DateTime(2026, 10, 14));
      now = DateTime(2026, 10, 15, 0, 0, 1);
      async.elapse(const Duration(seconds: 31));
      expect(seen.last, DateTime(2026, 10, 15));
    });
  });
}
