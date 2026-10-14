import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/db.dart';
import 'state/core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded before the first frame so theme and language apply immediately.
  final prefs = await SharedPreferences.getInstance();
  final db = await openAppDb(databaseFactory, p.join(await getDatabasesPath(), 'nihonkoe.db'));
  runApp(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs), dbProvider.overrideWithValue(db)],
    retry: retryPolicy,
    child: const NihonkoeApp(),
  ));
}
