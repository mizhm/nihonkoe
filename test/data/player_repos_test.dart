import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/data/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  var clock = 0;

  setUp(() async {
    db = await openAppDb(databaseFactoryFfi, inMemoryDatabasePath);
    clock = 0;
  });
  tearDown(() => db.close());

  test('positions: save, read, overwrite and clear', () async {
    final repo = PositionsRepo(db, now: () => ++clock);
    expect(await repo.get('5:0'), isNull);
    await repo.save('5:0', 120.5);
    await repo.save('5:0', 130);
    expect(await repo.get('5:0'), 130);
    await repo.save('5:0', null);
    expect(await repo.get('5:0'), isNull);
  });

  test('positions: inProgress prefers the first stream and ignores other works', () async {
    final repo = PositionsRepo(db, now: () => ++clock);
    await repo.save('5:1', 30);
    await repo.save('50:0', 99);
    expect(await repo.inProgress(5), 30);
    await repo.save('5:0', 120);
    expect(await repo.inProgress(5), 120);
    expect(await repo.inProgress(6), isNull);
  });

  test('history: one row per work, replaying updates the time and details', () async {
    final repo = HistoryRepo(db, now: () => ++clock);
    await repo.recordPlay(const PostRef(id: 5, title: 'Old', cv: 'A'));
    await repo.recordPlay(const PostRef(id: 6, title: 'Other'));
    await repo.recordPlay(const PostRef(id: 5, title: 'New', cv: 'B', rjCode: 'RJ1', circle: 'C', cover: 'x.jpg'));
    final rows = await db.query('history', orderBy: 'played_at DESC');
    expect(rows.length, 2);
    expect(rows.first, {'post_id': 5, 'title': 'New', 'cover': 'x.jpg', 'cv': 'B', 'rj_code': 'RJ1', 'circle': 'C', 'played_at': 3});
  });
}
