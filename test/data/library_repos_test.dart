import 'package:flutter_test/flutter_test.dart';
import 'package:nihonkoe/api/models.dart';
import 'package:nihonkoe/data/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  var clock = 0;
  int now() => ++clock;

  setUp(() async {
    db = await openAppDb(databaseFactoryFfi, inMemoryDatabasePath);
    clock = 0;
  });
  tearDown(() => db.close());

  PostRef ref(int id) => PostRef(id: id, title: 't$id', cover: 'c$id', cv: 'cv$id', rjCode: 'RJ$id', circle: 'circle$id');

  test('favorites toggle on and off, newest first, keeping every field', () async {
    final repo = FavoritesRepo(db, now: now);
    expect(await repo.toggle(ref(1)), isTrue);
    expect(await repo.toggle(ref(2)), isTrue);
    expect([for (final p in await repo.list()) p.id], [2, 1]);
    final first = (await repo.list()).last;
    expect((first.title, first.cover, first.cv, first.rjCode, first.circle), ('t1', 'c1', 'cv1', 'RJ1', 'circle1'));
    expect(await repo.toggle(ref(1)), isFalse);
    expect([for (final p in await repo.list()) p.id], [2]);
  });

  test('history lists newest first, removes one and clears all', () async {
    final repo = HistoryRepo(db, now: now);
    await repo.recordPlay(ref(1));
    await repo.recordPlay(ref(2));
    await repo.recordPlay(ref(1));
    expect([for (final e in await repo.list()) (e.post.id, e.playedAt)], [(1, 3), (2, 2)]);
    await repo.remove(1);
    expect([for (final e in await repo.list()) e.post.id], [2]);
    await repo.clear();
    expect(await repo.list(), isEmpty);
  });

  test('ratings: set, update, list best first, 0 removes', () async {
    final repo = RatingsRepo(db, now: now);
    await repo.set(ref(1), 3);
    await repo.set(ref(2), 5);
    await repo.set(ref(3), 3);
    await repo.set(ref(1), 4);
    expect([for (final r in await repo.list()) (r.post.id, r.rating)], [(2, 5), (1, 4), (3, 3)]);
    await repo.set(ref(2), 0);
    expect([for (final r in await repo.list()) r.post.id], [1, 3]);
  });

  test('clearing history keeps favorites, ratings and listening positions', () async {
    await FavoritesRepo(db, now: now).toggle(ref(1));
    await RatingsRepo(db, now: now).set(ref(1), 4);
    await PositionsRepo(db, now: now).save('1:0', 120);
    final history = HistoryRepo(db, now: now);
    await history.recordPlay(ref(1));
    await history.clear();
    expect((await FavoritesRepo(db).list()).single.id, 1);
    expect((await RatingsRepo(db).list()).single.rating, 4);
    expect(await PositionsRepo(db).get('1:0'), 120);
  });
}
