import 'package:sqflite/sqflite.dart';

const _postColumns = 'post_id INTEGER PRIMARY KEY, title TEXT NOT NULL, cover TEXT, cv TEXT, rj_code TEXT, circle TEXT';

Future<void> createSchema(Database db, int version) async {
  final batch = db.batch()
    ..execute('CREATE TABLE favorites($_postColumns, added_at INTEGER NOT NULL)')
    ..execute('CREATE TABLE history($_postColumns, played_at INTEGER NOT NULL)')
    ..execute('CREATE INDEX history_played_at ON history(played_at)')
    ..execute('CREATE TABLE ratings($_postColumns, rating INTEGER NOT NULL, rated_at INTEGER NOT NULL)')
    // Kept apart from the library so the frequent position writes stay small. key = "$postId:$streamIndex".
    ..execute('CREATE TABLE positions(key TEXT PRIMARY KEY, seconds REAL NOT NULL, updated_at INTEGER NOT NULL)')
    ..execute('CREATE TABLE search_history(query TEXT PRIMARY KEY, searched_at INTEGER NOT NULL)');
  await batch.commit(noResult: true);
}

Future<Database> openAppDb(DatabaseFactory factory, String path) =>
    factory.openDatabase(path, options: OpenDatabaseOptions(version: 1, onCreate: createSchema));

class SearchHistoryRepo {
  SearchHistoryRepo(this._db, {int Function()? now}) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);
  final Database _db;
  final int Function() _now;
  static const limit = 10;

  Future<List<String>> list() async {
    final rows = await _db.query('search_history', orderBy: 'searched_at DESC, rowid DESC', limit: limit);
    return [for (final r in rows) r['query']! as String];
  }

  Future<void> push(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await _db.transaction((txn) async {
      // SQLite's lower() is ASCII-only, so compare folded forms in Dart (the table holds at most [limit] rows).
      final key = _fold(q);
      for (final row in await txn.query('search_history', columns: ['query'])) {
        final existing = row['query']! as String;
        if (_fold(existing) == key) await txn.delete('search_history', where: 'query = ?', whereArgs: [existing]);
      }
      await txn.insert('search_history', {'query': q, 'searched_at': _now()});
      await txn.execute(
        'DELETE FROM search_history WHERE rowid NOT IN '
        '(SELECT rowid FROM search_history ORDER BY searched_at DESC, rowid DESC LIMIT $limit)',
      );
    });
  }

  Future<void> remove(String query) => _db.delete('search_history', where: 'query = ?', whereArgs: [query]);

  Future<void> clear() => _db.delete('search_history');
}

/// Case- and width-insensitive key: Japanese IMEs type full-width Latin (ＡＳＭＲ) and ideographic spaces.
String _fold(String s) => String.fromCharCodes(s.runes.map((c) => switch (c) {
      0x3000 => 0x20,
      >= 0xFF01 && <= 0xFF5E => c - 0xFEE0,
      _ => c,
    })).toLowerCase();
