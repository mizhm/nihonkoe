import 'package:sqflite/sqflite.dart';

import '../api/models.dart';
import '../logic/library.dart';
import '../logic/position.dart';

const _postColumns = 'post_id INTEGER PRIMARY KEY, title TEXT NOT NULL, cover TEXT, cv TEXT, rj_code TEXT, circle TEXT';

Map<String, Object?> _postRow(PostRef p) =>
    {'post_id': p.id, 'title': p.title, 'cover': p.cover, 'cv': p.cv, 'rj_code': p.rjCode, 'circle': p.circle};

PostRef _postFrom(Map<String, Object?> r) => PostRef(
      id: r['post_id']! as int,
      title: r['title']! as String,
      cover: r['cover'] as String?,
      cv: r['cv'] as String?,
      rjCode: r['rj_code'] as String?,
      circle: r['circle'] as String?,
    );

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

class PositionsRepo {
  PositionsRepo(this._db, {int Function()? now}) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);
  final Database _db;
  final int Function() _now;

  Future<double?> get(String key) async {
    final rows = await _db.query('positions', columns: ['seconds'], where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : (rows.single['seconds']! as num).toDouble();
  }

  /// `null` clears the position (the stream was finished).
  Future<void> save(String key, double? seconds) => seconds == null
      ? _db.delete('positions', where: 'key = ?', whereArgs: [key])
      : _db.insert('positions', {'key': key, 'seconds': seconds, 'updated_at': _now()},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<ResumePoint?> inProgress(int postId) async {
    final rows = await _db.query('positions', columns: ['key', 'seconds'], where: 'key LIKE ?', whereArgs: ['$postId:%']);
    return inProgressPosition({for (final r in rows) r['key']! as String: (r['seconds']! as num).toDouble()}, postId);
  }
}

class HistoryRepo {
  HistoryRepo(this._db, {int Function()? now}) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);
  final Database _db;
  final int Function() _now;

  Future<void> recordPlay(PostRef post) =>
      _db.insert('history', {..._postRow(post), 'played_at': _now()}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<HistoryEntry>> list() async => [
        for (final r in await _db.query('history', orderBy: 'played_at DESC'))
          HistoryEntry(post: _postFrom(r), playedAt: r['played_at']! as int),
      ];

  Future<void> remove(int postId) => _db.delete('history', where: 'post_id = ?', whereArgs: [postId]);

  /// Only the history table: favorites, ratings and listening positions stay.
  Future<void> clear() => _db.delete('history');
}

class FavoritesRepo {
  FavoritesRepo(this._db, {int Function()? now}) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);
  final Database _db;
  final int Function() _now;

  Future<List<PostRef>> list() async => [for (final r in await _db.query('favorites', orderBy: 'added_at DESC')) _postFrom(r)];

  Future<bool> toggle(PostRef post) => _db.transaction((txn) async {
        final removed = await txn.delete('favorites', where: 'post_id = ?', whereArgs: [post.id]);
        if (removed > 0) return false;
        await txn.insert('favorites', {..._postRow(post), 'added_at': _now()});
        return true;
      });
}

class RatingsRepo {
  RatingsRepo(this._db, {int Function()? now}) : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);
  final Database _db;
  final int Function() _now;

  Future<List<RatedPost>> list() async => [
        for (final r in await _db.query('ratings', orderBy: 'rating DESC, rated_at DESC'))
          RatedPost(post: _postFrom(r), rating: r['rating']! as int),
      ];

  Future<void> set(PostRef post, int rating) => rating <= 0
      ? _db.delete('ratings', where: 'post_id = ?', whereArgs: [post.id])
      : _db.insert('ratings', {..._postRow(post), 'rating': rating.clamp(1, 5), 'rated_at': _now()},
          conflictAlgorithm: ConflictAlgorithm.replace);
}
