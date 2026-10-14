import 'package:flutter_test/flutter_test.dart';
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

  SearchHistoryRepo repo() => SearchHistoryRepo(db, now: () => ++clock);

  test('creates every table from the spec', () async {
    final tables = (await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'")).map((r) => r['name']);
    expect(tables, containsAll(['favorites', 'history', 'ratings', 'positions', 'search_history']));
  });

  test('push keeps newest first and ignores blank queries', () async {
    final r = repo();
    await r.push('ear');
    await r.push('  ');
    await r.push(' binaural ');
    expect(await r.list(), ['binaural', 'ear']);
  });

  test('a repeat search differing only in case moves to the top once', () async {
    final r = repo();
    await r.push('Ear');
    await r.push('other');
    await r.push('ear');
    expect(await r.list(), ['ear', 'other']);
  });

  test('history is capped at 10', () async {
    final r = repo();
    for (var i = 0; i < 12; i++) {
      await r.push('q$i');
    }
    final list = await r.list();
    expect(list.length, 10);
    expect(list.first, 'q11');
    expect(list, isNot(contains('q0')));
  });

  test('remove and clear', () async {
    final r = repo();
    await r.push('a');
    await r.push('b');
    await r.remove('a');
    expect(await r.list(), ['b']);
    await r.clear();
    expect(await r.list(), isEmpty);
  });

  test('full-width and half-width forms of the same query are one entry (Japanese IME)', () async {
    final r = repo();
    await r.push('ＡＳＭＲ　耳かき');
    await r.push('asmr 耳かき');
    expect(await r.list(), ['asmr 耳かき']);
  });
}
