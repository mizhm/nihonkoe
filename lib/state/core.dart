import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../api/client.dart';
import '../api/models.dart';

final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main'));
final dbProvider = Provider<Database>((ref) => throw UnimplementedError('overridden in main'));

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(httpClientProvider)));

final cacheDirProvider = FutureProvider<Directory>((ref) => getApplicationCacheDirectory());

/// Overridden in widget tests so images don't touch the disk cache.
final imageProviderFactory = Provider<ImageProvider Function(String url)>(
  (ref) => (url) => CachedNetworkImageProvider(url, headers: mediaHeaders),
);

/// Failed providers retry twice: 0.5 s, then 1 s.
Duration? retryPolicy(int retryCount, Object error) =>
    retryCount < 2 ? Duration(milliseconds: 500 << retryCount) : null;

extension CacheFor on Ref {
  /// Keeps an auto-dispose provider's state for [duration] after its last listener leaves.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
