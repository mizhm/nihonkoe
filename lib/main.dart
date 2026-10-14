import 'package:material_ui/material_ui.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/db.dart';
import 'player/engine.dart';
import 'player/handler.dart';
import 'state/core.dart';
import 'state/player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loaded before the first frame so theme and language apply immediately.
  final prefs = await SharedPreferences.getInstance();
  final db = await openAppDb(databaseFactory, p.join(await getDatabasesPath(), 'nihonkoe.db'));
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  final handler = await AudioService.init(
    builder: () => NihonkoeAudioHandler(
      engine: JustAudioEngine(),
      positions: PositionsRepo(db),
      history: HistoryRepo(db),
      // Playback can start from a media button before any UI builds; respect privacy from the first track.
      hideArtwork: prefs.getBool('privacy') ?? false,
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'dev.local.nihonkoe.playback',
      androidNotificationChannelName: 'Playback',
      fastForwardInterval: Duration(seconds: 30),
      rewindInterval: Duration(seconds: 15),
    ),
  );
  runApp(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      dbProvider.overrideWithValue(db),
      audioHandlerProvider.overrideWithValue(handler),
    ],
    retry: retryPolicy,
    child: const NihonkoeApp(),
  ));
}
